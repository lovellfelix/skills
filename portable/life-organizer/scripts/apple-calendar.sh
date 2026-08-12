#!/usr/bin/env bash
set -euo pipefail

# Apple Calendar integration for personal assistant
# Uses osascript (AppleScript) to read/write calendar events
# Syncs across all Apple devices via iCloud automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer shared lib in same scripts directory, but tolerate alternative paths
if [[ -f "$SCRIPT_DIR/lib/error-handling.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/lib/error-handling.sh"
else
  # minimal fallbacks with actionable hints
  die() { echo "ERROR: $*" >&2; exit 1; }
  log_error() { echo "ERROR: $*" >&2; }
  log_warn() { echo "WARN: $*" >&2; }
  log_info() { echo "INFO: $*"; }
fi

# Escape strings for safe AppleScript interpolation
escape_as_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

usage() {
  cat <<EOF
Usage: apple-calendar.sh <command> [options]

Commands:
  today                     Show today's events
  tomorrow                  Show tomorrow's events
  week                      Show this week's events
  range <start> <end>       Show events in date range (YYYY-MM-DD)
  search <query>            Search events by title
  add <cal> <title> <start> <end> [location] [notes]
                              Add event (dates: "YYYY-MM-DD HH:MM")
  delete <event_id>          Delete an event by identifier
  dedupe <title> <start> <end> [keep_calendar]
                              Delete duplicates for an exact title + time
  calendars                 List available calendars

Options:
  --json                    Output machine-readable JSON

Examples:
  apple-calendar.sh today
  apple-calendar.sh week
  apple-calendar.sh range 2026-02-18 2026-02-25
  apple-calendar.sh search "standup"
  apple-calendar.sh add Work "Team Standup" "2026-02-19 09:00" "2026-02-19 09:30"
  apple-calendar.sh add Work "Client Meeting" "2026-02-19 14:00" "2026-02-19 15:00" "Conference Room A"
  apple-calendar.sh add Personal "Doctor Appointment" "2026-02-20 10:00" "2026-02-20 11:00" "123 Medical Plaza" "Annual checkup"
  apple-calendar.sh delete "<event_id>"
  apple-calendar.sh dedupe "Outdoor Movie Night" "2026-02-20 19:00" "2026-02-20 21:00" "Family"
  apple-calendar.sh calendars
EOF
}

want_json=0
filtered_args=()
for arg in "$@"; do
  if [[ "$arg" == "--json" ]]; then
    want_json=1
  else
    filtered_args+=("$arg")
  fi
done
set -- "${filtered_args[@]}"

run_with_timeout() {
  local seconds="$1"
  shift

    if command -v timeout >/dev/null 2>&1; then
      if ! timeout "${seconds}s" "$@"; then
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
          log_error "Operation timed out after ${seconds}s"
          log_info "Tip: Check Calendar.app permissions in System Settings > Privacy & Security and retry"
          return 124
        fi
        return "$exit_code"
      fi
  elif command -v gtimeout >/dev/null 2>&1; then
    if ! gtimeout "${seconds}s" "$@"; then
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        log_error "Operation timed out after ${seconds}s"
        return 124
      fi
      return "$exit_code"
    fi
  else
    # No timeout - use perl fallback
    perl -e 'alarm $ARGV[0]; exec @ARGV[1..$#ARGV]' "$seconds" "$@"
  fi
}

tsv_to_json() {
  if ! command -v python3 >/dev/null 2>&1; then
    log_error "python3 is required for --json output"
    log_info "Install: brew install python3 (macOS) or system package manager"
    return 1
  fi
  python3 -c 'import json,sys
events=[]
for raw in sys.stdin.read().splitlines():
    if not raw.strip():
        continue
    parts = raw.split("\t")
    if len(parts) >= 6:
        cal, start, end, title, loc, notes = parts[:6]
        events.append({"calendar": cal, "start": start, "end": end, "title": title, "location": loc, "notes": notes})
    elif len(parts) >= 3:
        cal, start, title = parts[:3]
        events.append({"calendar": cal, "start": start, "title": title})
print(json.dumps(events, ensure_ascii=True))'
}

list_calendars() {
  local output
  if ! output=$(run_with_timeout 8 osascript - 2>&1 <<'APPLESCRIPT'
tell application "Calendar"
  launch
  delay 0.2
  set out to ""
  repeat with c in calendars
    set accName to ""
    try
      set accName to (name of account of c) as text
    end try
    if accName is not "" then
      set out to out & (name of c) & " (" & accName & ")" & linefeed
    else
      set out to out & (name of c) & linefeed
    end if
  end repeat
  return out
end tell
APPLESCRIPT
); then
    log_error "Could not list calendars"
    log_info "Check Calendar.app permissions in System Settings > Privacy & Security and ensure Automation to osascript is allowed"
    printf '%s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output"
}

get_events_range() {
  local start_date="$1"
  local end_date="$2"

  local output
  if ! output=$(run_with_timeout 8 osascript - "$start_date" "$end_date" 2>&1 <<'APPLESCRIPT'
on run argv
  set startDate to date (item 1 of argv)
  set endDate to date (item 2 of argv)
  set t to ASCII character 9

  tell application "Calendar" to launch
  delay 0.2

  tell application "Calendar"
    set out to ""
    repeat with c in calendars
      set calName to name of c
      try
        set evts to (every event of c whose start date >= startDate and start date < endDate)
        repeat with e in evts
          set eStart to start date of e
          set eEnd to end date of e
          set eTitle to my cleanText(summary of e)

          set eLoc to ""
          try
            set eLoc to my cleanText(location of e)
          end try

          set eNotes to ""
          try
            set eNotes to my cleanText(description of e)
          end try

          set startStr to (year of eStart as text) & "-" & my padNum(month of eStart as integer) & "-" & my padNum(day of eStart) & " " & my padNum(hours of eStart) & ":" & my padNum(minutes of eStart)
          set endStr to (year of eEnd as text) & "-" & my padNum(month of eEnd as integer) & "-" & my padNum(day of eEnd) & " " & my padNum(hours of eEnd) & ":" & my padNum(minutes of eEnd)

          if eLoc is missing value then set eLoc to ""
          if eNotes is missing value then set eNotes to ""

          set firstNote to ""
          if eNotes is not "" then
            try
              set firstNote to paragraph 1 of eNotes
            end try
          end if

          set out to out & calName & t & startStr & t & endStr & t & eTitle & t & eLoc & t & my cleanText(firstNote) & linefeed
        end repeat
      end try
    end repeat
    return out
  end tell
end run

on cleanText(s)
  if s is missing value then return ""
  set txt to s as text

  set text item delimiters of AppleScript to ASCII character 9
  set items1 to text items of txt
  set text item delimiters of AppleScript to " "
  set txt to items1 as text

  set text item delimiters of AppleScript to linefeed
  set items2 to text items of txt
  set text item delimiters of AppleScript to " "
  set txt to items2 as text

  set text item delimiters of AppleScript to ""
  return txt
end cleanText

on padNum(n)
  if n < 10 then
    return "0" & (n as text)
  else
    return n as text
  end if
end padNum
APPLESCRIPT
); then
    echo "(error: could not query calendar events)" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output" | awk 'NF' | sort -t$'\t' -k2
}

today_events() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json today
  else
    swift "${script_dir}/apple-calendar-fast.swift" today
  fi
}

tomorrow_events() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json tomorrow
  else
    swift "${script_dir}/apple-calendar-fast.swift" tomorrow
  fi
}

week_events() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json week
  else
    swift "${script_dir}/apple-calendar-fast.swift" week
  fi
}

range_events() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json range "$1" "$2"
  else
    swift "${script_dir}/apple-calendar-fast.swift" range "$1" "$2"
  fi
}

search_events() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json search "$1"
  else
    swift "${script_dir}/apple-calendar-fast.swift" search "$1"
  fi
}

add_event() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    swift "${script_dir}/apple-calendar-fast.swift" --json add "$1" "$2" "$3" "$4" "${5:-}" "${6:-}"
  else
    swift "${script_dir}/apple-calendar-fast.swift" add "$1" "$2" "$3" "$4" "${5:-}" "${6:-}"
  fi
}

case "${1:-help}" in
  today)
    today_events
    ;;
  tomorrow)
    tomorrow_events
    ;;
  week)
    week_events
    ;;
  range)
    range_events "${2:?start date required}" "${3:?end date required}"
    ;;
  search)
    search_events "${2:?query required}"
    ;;
  add)
    add_event "${2:?calendar required}" "${3:?title required}" "${4:?start required}" "${5:?end required}" "${6:-}" "${7:-}"
    ;;
  delete)
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ $want_json -eq 1 ]]; then
      swift "${script_dir}/apple-calendar-fast.swift" --json delete "${2:?event id required}"
    else
      swift "${script_dir}/apple-calendar-fast.swift" delete "${2:?event id required}"
    fi
    ;;
  dedupe)
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ $want_json -eq 1 ]]; then
      swift "${script_dir}/apple-calendar-fast.swift" --json dedupe "${2:?title required}" "${3:?start required}" "${4:?end required}" "${5:-}"
    else
      swift "${script_dir}/apple-calendar-fast.swift" dedupe "${2:?title required}" "${3:?start required}" "${4:?end required}" "${5:-}"
    fi
    ;;
  calendars)
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ $want_json -eq 1 ]]; then
      swift "${script_dir}/apple-calendar-fast.swift" --json calendars
    else
      swift "${script_dir}/apple-calendar-fast.swift" calendars
    fi
    ;;
  help|*)     usage ;;
esac
