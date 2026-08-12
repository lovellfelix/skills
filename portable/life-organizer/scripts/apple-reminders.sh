#!/usr/bin/env bash
set -euo pipefail

# Apple Reminders integration for personal assistant
# Uses osascript (AppleScript) to read/write reminders
# Syncs across all Apple devices via iCloud automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared error/log helpers, fallback if missing
if [[ -f "$SCRIPT_DIR/lib/error-handling.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/lib/error-handling.sh"
else
  die() { echo "ERROR: $*" >&2; exit 1; }
  log_error() { echo "ERROR: $*" >&2; }
  log_warn() { echo "WARN: $*" >&2; }
  log_info() { echo "INFO: $*"; }
  require_command() { if ! command -v "$1" &>/dev/null; then log_error "Required command not found: $1"; [[ -n "$2" ]] && log_info "Install: $2"; return 1; fi; return 0; }
fi

# Escape strings for safe AppleScript interpolation
escape_as_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

usage() {
  cat <<EOF
Usage: apple-reminders.sh <command> [options]

Options:
  --json                    Output machine-readable JSON (query commands only)

Commands:
  lists                     List all reminder lists
  show <list>               Show incomplete reminders in a list
  all                       Show all incomplete reminders across all lists
  overdue                   Show overdue reminders
  today                     Show reminders due today
  add <list> <title> [due_date] [notes] [priority] [location] [tags]
                            Add a reminder (due: "YYYY-MM-DD HH:MM", priority: 1-9, 0=none, location: actual location string)
  update <list> <old_title> [new_title] [due_date] [notes] [priority] [location] [tags]
                            Update an existing reminder (use "none" for due_date/location to clear)
  bulk-update <list> [due_date] [notes] [priority] [location] [tags]
                            Update ALL incomplete reminders in a list (use "none" for due_date/location to clear)
  normalize <list>
                            Normalize legacy note metadata (hashtags + location alarms)
  strip-tags <list> [title]
                            Remove tags (hashtags) from notes (optionally only matching title)
  complete <list> <title>   Mark a reminder as complete
  rename <old_name> <new_name>
                            Rename a reminder list
  search <query>            Search reminders by title
  add-tags <list> <title> <tags>
                            Native tag application is not supported; use hashtags in notes/description instead
  search-tag <tag>          Search reminders by tag
                            Note: Reminders.app smart lists cannot be created/deleted via this script.
                            Create smart lists manually in Reminders.app and rely on hashtags in notes for grouping.
                            Tag search/filter works when reminders include hashtags like #roadtrip2026 in notes.
  smart-today               Show reminders due today (Today smart list)
  smart-scheduled           Show scheduled reminders (Scheduled smart list)
  smart-flagged             Show high-priority reminders (Flagged smart list)

Examples:
  apple-reminders.sh lists
  apple-reminders.sh show Work
  apple-reminders.sh all
  apple-reminders.sh overdue
  apple-reminders.sh today
  apple-reminders.sh overdue --json
  apple-reminders.sh today --json
  apple-reminders.sh add Work "Review PR" "2026-02-19 10:00" "Auth service PR" "" "Office Building A"
  apple-reminders.sh update Work "Review PR" "Review Auth PR" "2026-02-20 14:00" "Updated deadline" "" "Conference Room B"
  apple-reminders.sh update Work "Review PR" "" "none" "Cleared due date and location" "" "none"
  apple-reminders.sh update "Family Bucket List" --title "Tulips Picking at Texas Tulips" --notes "Tickets required" --location "Pilot Point, Texas"
  apple-reminders.sh bulk-update "Family Bucket List" "" "Refined metadata" "" "" "family,weekend"
  apple-reminders.sh update "Family Bucket List" --notes "Refined metadata"   # shorthand for bulk-update
  apple-reminders.sh update "Family Bucket List" --title "Tulips Picking at Texas Tulips" --tags "family,weekend" --location "Pilot Point, Texas"
  apple-reminders.sh normalize "Family Bucket List"                             # migrate [tags:]/[location:] metadata
  apple-reminders.sh strip-tags "Family Bucket List" "Tulips Picking at Texas Tulips"
  apple-reminders.sh complete Work "Review PR"
  apple-reminders.sh rename "Work" "Personal"
  apple-reminders.sh search "grocery"
  apple-reminders.sh add-tags Work "Deploy API" "urgent,backend"
  apple-reminders.sh search-tag "urgent"
  apple-reminders.sh search-tag "roadtrip"
  apple-reminders.sh smart-today
  apple-reminders.sh smart-scheduled
  apple-reminders.sh smart-flagged
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
        log_info "Tip: Check Reminders.app permissions in System Settings > Privacy & Security and Automation allowance for terminal/osascript"
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
    # No timeout command available - run without timeout
    "$@"
  fi
}

extract_tags_from_notes() {
  # Input: notes string
  # Output: "<clean_notes>" and sets global EXTRACTED_TAGS
  #
  # Supports:
  # - legacy: [tags:family,weekend]
  # - hashtags in notes: "... #family #weekend"
  local notes_in="${1:-}"
  EXTRACTED_TAGS=""

  if [[ -z "$notes_in" ]]; then
    printf '%s' ""
    return 0
  fi

  # Extract legacy [tags:...]
  local legacy
  legacy=$(printf '%s' "$notes_in" | sed -n 's/.*\[tags:\([^]]*\)\].*/\1/p' | head -n1 || true)
  if [[ -n "$legacy" ]]; then
    EXTRACTED_TAGS="$legacy"
    notes_in=$(printf '%s' "$notes_in" | sed 's/\[tags:[^]]*\]//g')
  fi

  # Extract hashtags (#tag, allows dash/underscore)
  local hash_tags
  hash_tags=$(printf '%s' "$notes_in" | tr '\n' ' ' | grep -oE '#[A-Za-z0-9_-]+' 2>/dev/null | sed 's/^#//' | tr '\n' ',' | sed 's/,$//' || true)
  if [[ -n "$hash_tags" ]]; then
    if [[ -n "$EXTRACTED_TAGS" ]]; then
      EXTRACTED_TAGS="${EXTRACTED_TAGS},${hash_tags}"
    else
      EXTRACTED_TAGS="$hash_tags"
    fi
    notes_in=$(printf '%s' "$notes_in" | sed -E 's/(^|[[:space:]])#[A-Za-z0-9_-]+//g')
  fi

  # Cleanup whitespace
  notes_in=$(printf '%s' "$notes_in" | sed -E 's/[[:space:]]+/ /g; s/^ +| +$//g')
  printf '%s' "$notes_in"
}

list_all_lists() {
  local output
  if ! output=$(osascript -e '
    tell application "Reminders"
      set output to ""
      repeat with l in lists
        set listName to name of l
        set incompleteCount to (count of (reminders of l whose completed is false))
        set output to output & listName & " (" & incompleteCount & " incomplete)" & linefeed
      end repeat
      return output
    end tell
  ' 2>&1); then
    log_error "Could not list reminder lists"
    log_info "Verify Reminders.app has necessary permissions"
    log_info "Check: System Settings > Privacy & Security > Automation"
    return 1
  fi
  printf '%s\n' "$output"
}

show_list() {
  local list_name="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  local swift_script="${script_dir}/apple-reminders-fast.swift"
  if [[ ! -f "$swift_script" ]]; then
    log_error "Swift helper not found: $swift_script"
    return 1
  fi
  
  local cmd_args=(list "$list_name")
  [[ $want_json -eq 1 ]] && cmd_args=(--json "${cmd_args[@]}")
  
  if ! run_with_timeout 15 swift -suppress-warnings "$swift_script" "${cmd_args[@]}"; then
    log_error "Failed to retrieve reminders from list: $list_name"
    log_info "Verify the list exists and is accessible"
    return 1
  fi
}

show_all() {
  # Use Swift EventKit for fast queries
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json all
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" all
  fi
}

show_overdue() {
  # Use Swift EventKit for fast date-based queries
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json overdue
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" overdue
  fi
}

show_today() {
  # Use Swift EventKit for fast date-based queries.
  # If there are no items due today, fall back to overdue items so
  # morning workflows still receive actionable reminders.
  local script_dir
  local output
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ $want_json -eq 1 ]]; then
    output=$(run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json today)
    if [[ "$output" == "[]" ]]; then
      run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json overdue
    else
      printf '%s\n' "$output"
    fi
  else
    output=$(run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" today)
    if [[ -z "${output//[[:space:]]/}" ]]; then
      run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" overdue
    else
      printf '%s\n' "$output"
    fi
  fi
}

add_reminder() {
  local list_name="$1"
  local title="$2"
  local due_date="${3:-}"
  local notes="${4:-}"
  local priority="${5:-0}"
  local location="${6:-}"
  local tags="${7:-}"

  # If caller embedded tags in notes, extract them.
  if [[ -z "$tags" && -n "$notes" ]]; then
    local clean
    clean=$(extract_tags_from_notes "$notes")
    if [[ -n "${EXTRACTED_TAGS:-}" ]]; then
      tags="$EXTRACTED_TAGS"
      notes="$clean"
    fi
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" add "$list_name" "$title" "$due_date" "$notes" "$priority" "$location" "$tags"
}

update_reminder() {
  local list_name="$1"
  shift

  # Flag-style support:
  # - Bulk update (shorthand): update <list> --notes "..." [--location "..."] [--priority N] [--due "..."]
  # - Single update:           update <list> --title "old" [--new-title "new"] [--notes "..."] ...
  if [[ ${1:-} == --* || ${1:-} == -* ]]; then
    local old_title=""
    local new_title=""
    local due_date=""
    local notes=""
    local priority=""
    local location=""
    local tags=""
    local do_all=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --all)
          do_all=1
          shift
          ;;
        --title)
          old_title="${2:?--title requires a value}"
          shift 2
          ;;
        --new-title)
          new_title="${2:?--new-title requires a value}"
          shift 2
          ;;
        --due)
          due_date="${2:?--due requires a value}"
          shift 2
          ;;
        --notes|--message|-m)
          notes="${2:?$1 requires a value}"
          shift 2
          ;;
        --tags)
          tags="${2:?--tags requires a value}"
          shift 2
          ;;
        --priority)
          priority="${2:?--priority requires a value}"
          shift 2
          ;;
        --location)
          location="${2:?--location requires a value}"
          shift 2
          ;;
        --)
          shift
          break
          ;;
        *)
          echo "(error: unknown update option: $1)" >&2
          echo "Tip: use positional syntax or: update <list> [--all] [--title <old>] [--new-title <new>] [--due <due|none>] [--notes <notes>] [--priority <0-9>] [--location <loc|none>]" >&2
          return 2
          ;;
      esac
    done

    # If caller embedded tags in notes, extract them (but only when --tags not provided).
    if [[ -z "$tags" && -n "$notes" ]]; then
      local clean
      clean=$(extract_tags_from_notes "$notes")
      if [[ -n "${EXTRACTED_TAGS:-}" ]]; then
        tags="$EXTRACTED_TAGS"
        notes="$clean"
      fi
    fi

    if [[ -z "$old_title" || $do_all -eq 1 ]]; then
      bulk_update_reminders "$list_name" "$due_date" "$notes" "$priority" "$location" "$tags"
      return $?
    fi

    # Single update via flags
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" update "$list_name" "$old_title" "$new_title" "$due_date" "$notes" "$priority" "$location" "$tags"
    return $?
  fi

  # Positional update
  local old_title="$1"
  local new_title="${2:-}"
  local due_date="${3:-}"
  local notes="${4:-}"
  local priority="${5:-}"
  local location="${6:-}"
  local tags="${7:-}"
  if [[ -z "$old_title" ]]; then
    echo "(error: old_title required)" >&2
    echo "Usage: apple-reminders.sh update <list> <old_title> [new_title] [due_date] [notes] [priority] [location]" >&2
    return 2
  fi

  # Heuristic: if due_date is non-empty but clearly NOT a date token and notes is empty,
  # the caller likely omitted the due_date placeholder, e.g.:
  #   update <list> <old_title> "" "<notes>" "" "<location>"
  # In that case, shift values into the intended slots.
  if [[ -n "$due_date" && -z "$notes" ]]; then
    if [[ "$due_date" != "none" && "$due_date" != "clear" && ! "$due_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}([[:space:]][0-9]{2}:[0-9]{2})?$ ]]; then
      # Common case: priority holds a location string because of the shift.
      if [[ -n "$priority" && -z "$location" && ! "$priority" =~ ^[0-9]$ ]]; then
        notes="$due_date"
        location="$priority"
        priority=""
        due_date="none"
      else
        echo "(error: invalid due_date token: '$due_date')" >&2
        echo "Tip: if you have no due date, pass 'none' as the 4th argument, or use flags:" >&2
        echo "  apple-reminders.sh update \"$list_name\" --title \"$old_title\" --notes \"...\" --location \"...\"" >&2
        return 2
      fi
    fi
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" update "$list_name" "$old_title" "$new_title" "$due_date" "$notes" "$priority" "$location" "$tags"
}

bulk_update_reminders() {
  local list_name="$1"
  local due_date="${2:-}"
  local notes="${3:-}"
  local priority="${4:-}"
  local location="${5:-}"
  local tags="${6:-}"

  # If caller embedded tags in notes, extract them.
  if [[ -z "$tags" && -n "$notes" ]]; then
    local clean
    clean=$(extract_tags_from_notes "$notes")
    if [[ -n "${EXTRACTED_TAGS:-}" ]]; then
      tags="$EXTRACTED_TAGS"
      notes="$clean"
    fi
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json bulk-update "$list_name" "$due_date" "$notes" "$priority" "$location" "$tags"
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" bulk-update "$list_name" "$due_date" "$notes" "$priority" "$location" "$tags"
  fi
}

normalize_list_metadata() {
  local list_name="$1"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json normalize "$list_name"
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" normalize "$list_name"
  fi
}

strip_tags() {
  local list_name="$1"
  local title="${2:-}"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json strip-tags "$list_name" "$title"
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" strip-tags "$list_name" "$title"
  fi
}

complete_reminder() {
  local list_name="$1"
  local title="$2"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" complete "$list_name" "$title"
}

add_reminder_with_tags() {
  local list_name="$1"
  local title="$2"
  local tags="${3:-}"

  echo "(error: native tag application is not supported)" >&2
  echo "Use hashtags in reminder notes/description instead, for example: #roadtrip2026" >&2
  echo "Reminder: add-tags was called for list '$list_name', title '$title', tags '$tags'." >&2
  return 1
}

search_by_tag() {
  local tag="$1"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json search-tag "$tag"
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" search-tag "$tag"
  fi
}



smart_list_today() {
  # Replicate "Today" smart list: reminders due today
  show_today
}

smart_list_scheduled() {
  # Replicate "Scheduled" smart list: reminders with due dates
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json scheduled
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" scheduled
  fi
}

smart_list_flagged() {
  # Replicate "Flagged" smart list: high-priority reminders (priority 1-4)
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json flagged
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" flagged
  fi
}

search_reminders() {
  local query="$1"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ $want_json -eq 1 ]]; then
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" --json search "$query"
  else
    run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" search "$query"
  fi
}

rename_list() {
  local old_name="$1"
  local new_name="$2"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  run_with_timeout 15 swift -suppress-warnings "${script_dir}/apple-reminders-fast.swift" rename "$old_name" "$new_name"
}

case "${1:-help}" in
  lists)          list_all_lists ;;
  show)           show_list "${2:?list name required}" ;;
  all)            show_all ;;
  overdue)        show_overdue ;;
  today)          show_today ;;
  add)            add_reminder "${2:?list required}" "${3:?title required}" "${4:-}" "${5:-}" "${6:-0}" "${7:-}" "${8:-}" ;;
  update)
    shift
    update_reminder "${1:?list required}" "${@:2}"
    ;;
  bulk-update)    bulk_update_reminders "${2:?list required}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" ;;
  normalize)      normalize_list_metadata "${2:?list required}" ;;
  strip-tags)     strip_tags "${2:?list required}" "${3:-}" ;;
  add-tags)       add_reminder_with_tags "${2:?list required}" "${3:?title required}" "${4:-}" ;;
  complete)       complete_reminder "${2:?list required}" "${3:?title required}" ;;
  rename)         rename_list "${2:?old name required}" "${3:?new name required}" ;;
  search)         search_reminders "${2:?query required}" ;;
  search-tag)     search_by_tag "${2:?tag required}" ;;
  smart-today)    smart_list_today ;;
  smart-scheduled) smart_list_scheduled ;;
  smart-flagged)  smart_list_flagged ;;
  help|*)         usage ;;
esac
