#!/usr/bin/env bash
set -euo pipefail

# Apple Notes integration for personal assistant
# Uses osascript (AppleScript) to read/write notes
# KEY INSIGHT: Apple Notes syncs via iCloud automatically
# This means data written here is available on ALL Apple devices
# Use this as a cross-device persistence layer for the assistant

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared error handling when available; otherwise provide minimal fallbacks
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

ASSISTANT_CONTEXT_NOTE_TITLE="Assistant Context"
ASSISTANT_PROFILE_NOTE_TITLE="User Profile"
ASSISTANT_TASKS_NOTE_TITLE="Active Tasks"
ASSISTANT_COLLECTION_TAG="#ai-assistant"
ASSISTANT_CONTEXT_TAG="#assistant-context"
ASSISTANT_PROFILE_TAG="#assistant-profile"
ASSISTANT_TASKS_TAG="#assistant-tasks"

# Escape strings for safe AppleScript interpolation
escape_as_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

extract_json_between_markers() {
  # Prints content between BEGIN_JSON and END_JSON markers.
  # Returns empty output if markers are missing.
  awk 'found { if ($0 ~ /^END_JSON[[:space:]]*$/) exit; print } /^BEGIN_JSON[[:space:]]*$/ { found=1 }'
}

normalize_hashtag() {
  local raw="${1-}"
  raw="${raw#\#}"
  raw=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr '[:space:]' '-' | tr -cd '[:alnum:]_-')
  if [[ -z "$raw" ]]; then
    return 1
  fi
  printf '#%s' "$raw"
}

normalize_tag_list() {
  local raw="${1-}"
  local token
  local normalized=()

  raw=${raw//,/ }
  for token in $raw; do
    if token=$(normalize_hashtag "$token"); then
      normalized+=("$token")
    fi
  done

  if [[ ${#normalized[@]} -eq 0 ]]; then
    return 1
  fi

  printf '%s' "${normalized[*]}"
}

tags_to_applescript_list() {
  local normalized_tags="${1-}"
  local tag
  local first=1

  printf '{'
  for tag in $normalized_tags; do
    if [[ $first -eq 0 ]]; then
      printf ', '
    fi
    printf '"%s"' "$(escape_as_string "$tag")"
    first=0
  done
  printf '}'
}

build_tag_html() {
  local normalized_tags="${1-}"
  if [[ -z "$normalized_tags" ]]; then
    return
  fi
  printf '<p>%s</p>' "$normalized_tags"
}

strip_html() {
  printf '%s' "${1-}" | perl -0pe 's/<[^>]+>/ /g'
}

escape_html() {
  perl -0pe 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g' <<<"${1-}"
}

run_with_timeout() {
  local seconds="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    if ! timeout "${seconds}s" "$@"; then
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        log_error "Operation timed out after ${seconds}s"
        log_info "Try: Check Notes.app permissions in System Settings"
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
    perl -e 'alarm $ARGV[0]; exec @ARGV[1..$#ARGV]' "$seconds" "$@"
  fi
}

usage() {
  cat <<EOF
Usage: apple-notes.sh <command> [options]

Options:
  --json                    Output JSON for supported commands

Commands:
  folders                   List all note folders
  list <folder>             List notes in a folder
  read <folder> <title>     Read a note's content
  write <folder> <title> <body>
                            Create or update a note (HTML body)
  append <folder> <title> <content>
                            Append content to existing note
  search <query>            Search notes by title
  search-tag <tag> [limit]  Search notes by hashtag in plaintext
  list-tags [limit]         List existing hashtags used across notes
  list-untagged [limit]     List notes with no hashtags in plaintext
  find-tagged <tags> [limit]
                            Find notes containing all specified hashtags
  suggest-tags <title> [body]
                            Suggest matching existing hashtags for a note
  read-tagged <tags> <title>
                            Read the first note matching all hashtags and title
  write-tagged [tags] <title> <body>
                            Create or update a tagged note; suggests tags if omitted
  append-tagged <tags> <title> <content>
                            Append content to a tagged note
  delete-tagged <tags> <title>
                            Delete a tagged note
  archive-note <folder> <title> [archive-folder]
                            Move a note to an archive folder
  archive-tagged <tags> <title> [archive-folder]
                            Move a tagged note to an archive folder
  re-tag-note <title> [existing-tags]
                            Refresh a note's hashtags from current suggestions
  link-personal-context <query-or-tags> [limit]
                            Show related notes, reminders, and events together
  improve-tag-cluster <tags> [limit]
                            Review a tag cluster and suggest retag/archive cleanup
  delete <folder> <title>   Delete a note

  -- Assistant-specific commands --
  sync-context <json>       Write assistant context to synced note
  read-context              Read assistant context from synced note
  sync-profile <json>       Write user profile to synced note
  read-profile              Read user profile from synced note
  sync-tasks <json>         Write active tasks to synced note
  read-tasks                Read active tasks from synced note
  ensure-folder             Legacy no-op for backward compatibility

Examples:
  apple-notes.sh folders
  apple-notes.sh read "✱ Work" "Meeting Notes"
  apple-notes.sh sync-context '{"priorities":["ship auth","fix bug"]}'
  apple-notes.sh read-context
  apple-notes.sh search-tag "work" 50
  apple-notes.sh list-tags 30
  apple-notes.sh list-untagged 30
  apple-notes.sh find-tagged "family,health" 20
  apple-notes.sh suggest-tags "Alice Dentist" "Next visit in June for school form"
  apple-notes.sh write-tagged "Alice Dentist" "<p>Next visit in June</p>"
  apple-notes.sh write-tagged "family,health" "Alice Dentist" "<p>Next visit in June</p>"
  apple-notes.sh archive-note "Notes" "Alice Dentist"
  apple-notes.sh re-tag-note "Alice Dentist" "family,health"
  apple-notes.sh link-personal-context "family,health" 10 --json
  apple-notes.sh link-personal-context "family,health" 10
  apple-notes.sh improve-tag-cluster "family,health" 20
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

list_folders() {
  local output
  if ! output=$(osascript -e '
    tell application "Notes"
      set output to ""
      repeat with f in folders
        set fName to name of f
        set noteCount to count of notes of f
        set output to output & fName & " (" & noteCount & " notes)" & linefeed
      end repeat
      return output
    end tell
  ' 2>&1); then
    log_error "Could not list note folders"
    log_info "Check Notes.app permissions in System Settings > Privacy & Security"
    return 1
  fi
  printf '%s\n' "$output"
}

list_notes_in_folder() {
  local folder_name
  folder_name=$(escape_as_string "$1")
  
  local output
  if ! output=$(osascript -e "
    tell application \"Notes\"
      try
        set targetFolder to folder \"${folder_name}\"
      on error
        error \"Folder not found: ${folder_name}\"
      end try
      set output to \"\"
      repeat with n in notes of targetFolder
        set nName to name of n
        set nDate to modification date of n
        set dateStr to (year of nDate as text) & \"-\" & my padNum(month of nDate as integer) & \"-\" & my padNum(day of nDate)
        set output to output & dateStr & \"\t\" & nName & linefeed
      end repeat
      return output
    end tell

    on padNum(num)
      if num < 10 then
        return \"0\" & (num as text)
      else
        return num as text
      end if
    end padNum
  " 2>&1); then
    log_error "Could not list notes in folder: $1"
    log_info "Verify folder exists and is accessible"
    return 1
  fi
  printf '%s\n' "$output"
}

read_note() {
  local folder_name
  folder_name=$(escape_as_string "$1")
  local note_title
  note_title=$(escape_as_string "$2")
  
  local output
  if ! output=$(osascript -e "
    tell application \"Notes\"
      try
        set targetFolder to folder \"${folder_name}\"
        set targetNote to first note of targetFolder whose name is \"${note_title}\"
      on error
        error \"Note not found: ${note_title} in ${folder_name}\"
      end try
      return plaintext of targetNote
    end tell
  " 2>&1); then
    echo "(error: could not read note; check folder and note name)" >&2
    return 1
  fi
  printf '%s\n' "$output"
}

write_note() {
  local folder_name
  folder_name=$(escape_as_string "$1")
  local note_title
  note_title=$(escape_as_string "$2")
  local note_body="$3"

  # Write body to temp file to avoid AppleScript escaping issues with JSON/HTML
  local tmpfile
  tmpfile=$(mktemp /tmp/apple-notes-XXXXXX.html)
  printf '%s' "<h1>${note_title}</h1>${note_body}" > "$tmpfile"

  local output
  local error_output
  if ! output=$(osascript \
    -e "set bodyFile to POSIX file \"${tmpfile}\"" \
    -e 'set noteBody to read bodyFile as «class utf8»' \
    -e "tell application \"Notes\"" \
    -e "  try" \
    -e "    set targetFolder to folder \"${folder_name}\"" \
    -e "  on error errMsg" \
    -e "    error \"Folder not found '${folder_name}': \" & errMsg" \
    -e "  end try" \
    -e '  set noteExists to false' \
    -e '  try' \
    -e "    set existingNote to first note of targetFolder whose name is \"${note_title}\"" \
    -e '    set noteExists to true' \
    -e '  end try' \
    -e '  if noteExists then' \
    -e '    try' \
    -e '      set body of existingNote to noteBody' \
    -e "      return \"Updated: ${note_title}\"" \
    -e '    on error errMsg' \
    -e '      error "Failed to update note: " & errMsg' \
    -e '    end try' \
    -e '  else' \
    -e '    try' \
    -e "      make new note at targetFolder with properties {name:\"${note_title}\", body:noteBody}" \
    -e "      return \"Created: ${note_title}\"" \
    -e '    on error errMsg' \
    -e '      error "Failed to create note: " & errMsg' \
    -e '    end try' \
    -e '  end if' \
    -e 'end tell' 2>&1); then
    error_output="$output"
    rm -f "$tmpfile"
    echo "(error: could not write note - ${error_output})" >&2
    return 1
  fi

  rm -f "$tmpfile"
  printf '%s\n' "$output"
}

append_to_note() {
  local folder_name
  folder_name=$(escape_as_string "$1")
  local note_title
  note_title=$(escape_as_string "$2")
  local content="$3"

  # Write content to temp file for safe AppleScript handling
  local tmpfile
  tmpfile=$(mktemp /tmp/apple-notes-XXXXXX.html)
  printf '%s' "$content" > "$tmpfile"

  local output
  if ! output=$(osascript \
    -e "set contentFile to POSIX file \"${tmpfile}\"" \
    -e 'set appendContent to read contentFile as «class utf8»' \
    -e "tell application \"Notes\"" \
    -e "  try" \
    -e "    set targetFolder to folder \"${folder_name}\"" \
    -e "    set targetNote to first note of targetFolder whose name is \"${note_title}\"" \
    -e "  on error" \
    -e "    error \"Note not found: ${note_title} in ${folder_name}\"" \
    -e "  end try" \
    -e '  set currentBody to body of targetNote' \
    -e '  set body of targetNote to currentBody & "<br>" & appendContent' \
    -e "  return \"Appended to: ${note_title}\"" \
    -e 'end tell' 2>&1); then
    rm -f "$tmpfile"
    echo "(error: could not append to note; check folder and note name)" >&2
    return 1
  fi

  rm -f "$tmpfile"
  printf '%s\n' "$output"
}

search_notes() {
  local query_raw="${1-}"
  local query
  query=$(escape_as_string "$query_raw")

  local limit="${2:-200}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=200
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=200
  fi
  
  local output
   if ! output=$(osascript -e "
     set q to \"${query}\"
     set maxRows to ${limit}
     tell application \"Notes\"
       set output to \"\"
       set rowCount to 0
       repeat with f in folders
         set fName to name of f
         repeat with n in notes of f
           set nName to name of n
            if q is \"\" or nName contains q then
              set isSensitive to false
              if nName contains \"API Key\" then set isSensitive to true
              if nName contains \"api key\" then set isSensitive to true
              if nName contains \"Password\" then set isSensitive to true
              if nName contains \"password\" then set isSensitive to true
              if nName contains \"Token\" then set isSensitive to true
              if nName contains \"token\" then set isSensitive to true
              if nName contains \"Secret\" then set isSensitive to true
              if nName contains \"secret\" then set isSensitive to true
              if nName contains \"Private Key\" then set isSensitive to true
              if nName contains \"private key\" then set isSensitive to true

              if isSensitive is false then
             set nDate to modification date of n
             set dateStr to (year of nDate as text) & \"-\" & my padNum(month of nDate as integer) & \"-\" & my padNum(day of nDate) & \" \" & my padNum(hours of nDate) & \":\" & my padNum(minutes of nDate)
             set output to output & fName & \"\t\" & dateStr & \"\t\" & nName & linefeed
             set rowCount to rowCount + 1
              if rowCount >= maxRows then exit repeat
              end if
            end if
         end repeat
         if rowCount >= maxRows then exit repeat
       end repeat

       if output is \"\" then
         return \"(no matches for: ${query})\"
       end if
       return output
     end tell

     on padNum(num)
       if num < 10 then
         return \"0\" & (num as text)
       else
         return num as text
       end if
     end padNum
   " 2>&1); then
    echo "(error: could not search notes; check Notes permissions)" >&2
    return 1
  fi

  # Sort by modification datetime descending, limit lines.
  printf '%s\n' "$output" | awk 'NF' | sort -t$'\t' -k2,2r | head -n "$limit"
}

search_notes_tag() {
  local tag_raw="${1:?tag required}"
  local limit="${2:-200}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=200
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=200
  fi

  local tag_value="$tag_raw"
  if [[ "$tag_value" != \#* ]]; then
    tag_value="#${tag_value}"
  fi
  local tag
  tag=$(escape_as_string "$tag_value")

  local output
  if ! output=$(run_with_timeout 12 osascript -e "
    set tagStr to \"${tag}\"
    set maxRows to ${limit}
    tell application \"Notes\"
      set output to \"\"
      set rowCount to 0
      try
        set matchingNotes to (every note whose plaintext contains tagStr)
      on error
        set matchingNotes to {}
      end try

      repeat with n in matchingNotes
        set nName to name of n
        set isSensitive to false
        if nName contains \"API Key\" then set isSensitive to true
        if nName contains \"api key\" then set isSensitive to true
        if nName contains \"Password\" then set isSensitive to true
        if nName contains \"password\" then set isSensitive to true
        if nName contains \"Token\" then set isSensitive to true
        if nName contains \"token\" then set isSensitive to true
        if nName contains \"Secret\" then set isSensitive to true
        if nName contains \"secret\" then set isSensitive to true
        if nName contains \"Private Key\" then set isSensitive to true
        if nName contains \"private key\" then set isSensitive to true

        if isSensitive is false then
          set fName to name of container of n
          set nDate to modification date of n
          set dateStr to (year of nDate as text) & \"-\" & my padNum(month of nDate as integer) & \"-\" & my padNum(day of nDate) & \" \" & my padNum(hours of nDate) & \":\" & my padNum(minutes of nDate)
          set output to output & fName & \"\\t\" & dateStr & \"\\t\" & nName & linefeed
          set rowCount to rowCount + 1
          if rowCount >= maxRows then exit repeat
        end if
      end repeat

      if output is \"\" then
        return \"(no matches for: ${tag_value})\"
      end if
      return output
    end tell

    on padNum(num)
      if num < 10 then
        return \"0\" & (num as text)
      else
        return num as text
      end if
    end padNum
  " 2>&1); then
    echo "(error: could not search notes by tag; check Notes permissions)" >&2
    return 1
  fi

  printf '%s\n' "$output" | awk 'NF' | sort -t$'\t' -k2,2r | head -n "$limit"
}

list_tags() {
  local limit="${1:-100}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=100
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=100
  fi

  local output
  if ! output=$(run_with_timeout 12 osascript -e '
    tell application "Notes"
      set output to ""
      repeat with f in folders
        repeat with n in notes of f
          set output to output & plaintext of n & linefeed
        end repeat
      end repeat
      return output
    end tell
  ' 2>&1); then
    echo "(error: could not list note tags; check Notes permissions)" >&2
    return 1
  fi

  printf '%s\n' "$output" | rg -o '#[A-Za-z][A-Za-z0-9_-]*' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr | awk '{print $2 "\t" $1}' | head -n "$limit"
}

list_untagged_notes() {
  local limit="${1:-100}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=100
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=100
  fi

  local output
  if ! output=$(run_with_timeout 12 osascript -e "
    set maxRows to ${limit}
    tell application \"Notes\"
      set output to \"\"
      set rowCount to 0
      repeat with f in folders
        set fName to name of f
        repeat with n in notes of f
          set noteText to plaintext of n
          if noteText does not contain \"#\" then
            set nDate to modification date of n
            set dateStr to (year of nDate as text) & \"-\" & my padNum(month of nDate as integer) & \"-\" & my padNum(day of nDate) & \" \" & my padNum(hours of nDate) & \":\" & my padNum(minutes of nDate)
            set output to output & fName & \"\\t\" & dateStr & \"\\t\" & (name of n) & linefeed
            set rowCount to rowCount + 1
            if rowCount >= maxRows then exit repeat
          end if
        end repeat
        if rowCount >= maxRows then exit repeat
      end repeat
      return output
    end tell

    on padNum(num)
      if num < 10 then
        return \"0\" & (num as text)
      else
        return num as text
      end if
    end padNum
  " 2>&1); then
    echo "(error: could not list untagged notes; check Notes permissions)" >&2
    return 1
  fi

  if [[ $want_json -eq 1 ]]; then
    LIST_UNTAGGED_OUTPUT="$output" python3 -c 'import json, os
rows=[]
for line in os.environ.get("LIST_UNTAGGED_OUTPUT", "").splitlines():
    parts=line.split("\t")
    if len(parts) >= 3:
        rows.append({"folder": parts[0], "modified_at": parts[1], "title": parts[2]})
print(json.dumps(rows, ensure_ascii=True))'
    return
  fi

  if [[ -z "$output" ]]; then
    printf 'No untagged notes\n'
    return 0
  fi

  printf '%s\n' "$output" | awk 'NF' | sort -t$'\t' -k2,2r | head -n "$limit"
}

find_tagged_notes() {
  local normalized_tags
  normalized_tags=$(normalize_tag_list "${1:?tags required}") || die "at least one valid tag is required"
  local limit="${2:-100}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=100
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=100
  fi

  local tag_list
  tag_list=$(tags_to_applescript_list "$normalized_tags")

  local output
  if ! output=$(run_with_timeout 12 osascript -e "
    set tagList to ${tag_list}
    set maxRows to ${limit}
    tell application \"Notes\"
      set output to \"\"
      set rowCount to 0
      repeat with f in folders
        set fName to name of f
        repeat with n in notes of f
          set noteText to plaintext of n
          if my noteHasAllTags(noteText, tagList) then
            set nDate to modification date of n
            set dateStr to (year of nDate as text) & \"-\" & my padNum(month of nDate as integer) & \"-\" & my padNum(day of nDate) & \" \" & my padNum(hours of nDate) & \":\" & my padNum(minutes of nDate)
            set output to output & fName & \"\\t\" & dateStr & \"\\t\" & (name of n) & linefeed
            set rowCount to rowCount + 1
            if rowCount >= maxRows then exit repeat
          end if
        end repeat
        if rowCount >= maxRows then exit repeat
      end repeat
      return output
    end tell

    on noteHasAllTags(noteText, tagList)
      repeat with currentTag in tagList
        if noteText does not contain (contents of currentTag) then
          return false
        end if
      end repeat
      return true
    end noteHasAllTags

    on padNum(num)
      if num < 10 then
        return \"0\" & (num as text)
      else
        return num as text
      end if
    end padNum
  " 2>&1); then
    echo "(error: could not find notes by tags; check Notes permissions)" >&2
    return 1
  fi

  if [[ -z "$output" ]]; then
    printf '(no matches for: %s)\n' "$normalized_tags"
    return 0
  fi

  printf '%s\n' "$output" | awk 'NF' | sort -t$'\t' -k2,2r | head -n "$limit"
}

suggest_tags() {
  local title="${1:?title required}"
  local body="${2-}"
  local haystack
  haystack=$(printf '%s %s' "$title" "$(strip_html "$body")" | tr '[:upper:]' '[:lower:]')

  local existing_tags
  if ! existing_tags=$(list_tags 200 2>/dev/null); then
    echo "(error: could not inspect existing tags)" >&2
    return 1
  fi

  if [[ -z "$existing_tags" ]]; then
    return 0
  fi

  local explicit_tags
  explicit_tags=$(printf '%s\n' "$haystack" | rg -o '#[a-z][a-z0-9_-]*' | sort -u || true)

  local line tag count bare score results=""
  while IFS=$'\t' read -r tag count; do
    [[ -z "$tag" ]] && continue
    bare=${tag#\#}
    score=0

    if [[ -n "$explicit_tags" ]] && printf '%s\n' "$explicit_tags" | rg -qx --fixed-strings "$tag"; then
      score=$((score + 10))
    fi

    if [[ "$haystack" == *"$bare"* ]]; then
      score=$((score + 6))
    fi

    IFS='-_' read -r -a parts <<< "$bare"
    if [[ ${#parts[@]} -gt 1 ]]; then
      local matched_parts=0
      local part
      for part in "${parts[@]}"; do
        if [[ ${#part} -ge 3 && "$haystack" == *"$part"* ]]; then
          matched_parts=$((matched_parts + 1))
        fi
      done
      score=$((score + matched_parts * 2))
    fi

    if [[ $score -gt 0 ]]; then
      results+="${score}\t${count}\t${tag}\n"
    fi
  done <<< "$existing_tags"

  if [[ -z "$results" ]]; then
    return 0
  fi

  printf '%b' "$results" | sort -t$'\t' -k1,1nr -k2,2nr -k3,3 | awk -F'\t' '!seen[$3]++ {print $3 "\t" $1}' | head -n 10
}

resolve_write_tagged_args() {
  if [[ $# -ge 3 ]]; then
    WRITE_TAGGED_TAGS="$1"
    WRITE_TAGGED_TITLE="$2"
    WRITE_TAGGED_BODY="$3"
    return 0
  fi

  if [[ $# -eq 2 ]]; then
    WRITE_TAGGED_TITLE="$1"
    WRITE_TAGGED_BODY="$2"
    WRITE_TAGGED_TAGS=$(suggest_tags "$WRITE_TAGGED_TITLE" "$WRITE_TAGGED_BODY" | awk -F'\t' '{print $1}' | head -n 5 | paste -sd, -)
    return 0
  fi

  die "write-tagged requires either <tags> <title> <body> or <title> <body>"
}

locate_note_by_title() {
  local title="${1:?title required}"
  local matches folder matched_title

  matches=$(search_notes "$title" 20 2>/dev/null || true)
  if [[ -z "$matches" || "$matches" == \(no\ matches* ]]; then
    return 1
  fi

  while IFS=$'\t' read -r folder _date matched_title; do
    if [[ "$matched_title" == "$title" ]]; then
      printf '%s\t%s\n' "$folder" "$matched_title"
      return 0
    fi
  done <<< "$matches"

  folder=$(printf '%s\n' "$matches" | awk -F'\t' 'NF>=3 {print $1; exit}')
  matched_title=$(printf '%s\n' "$matches" | awk -F'\t' 'NF>=3 {print $3; exit}')
  [[ -n "$folder" && -n "$matched_title" ]] || return 1
  printf '%s\t%s\n' "$folder" "$matched_title"
}

locate_tagged_note() {
  local tags="${1:?tags required}"
  local title="${2:?title required}"
  local matches folder matched_title

  matches=$(find_tagged_notes "$tags" 50 2>/dev/null || true)
  if [[ -z "$matches" || "$matches" == \(no\ matches* ]]; then
    return 1
  fi

  while IFS=$'\t' read -r folder _date matched_title; do
    if [[ "$matched_title" == "$title" ]]; then
      printf '%s\t%s\n' "$folder" "$matched_title"
      return 0
    fi
  done <<< "$matches"

  return 1
}

prepare_retag_plaintext() {
  local title="$1"
  local plaintext="$2"

  printf '%s\n' "$plaintext" | awk -v title="$title" '
    NR == 1 && $0 == title { next }
    !removed_tags && $0 ~ /^([[:space:]]*#[[:alnum:]_-]+[[:space:]]*)+$/ { removed_tags=1; next }
    { print }
  '
}

context_terms_from_input() {
  local raw="${1:?query or tags required}"
  local normalized_tags=""
  local query="$raw"

  if [[ "$raw" == *","* || "$raw" == *"#"* ]]; then
    normalized_tags=$(normalize_tag_list "$raw" 2>/dev/null || true)
    if [[ -n "$normalized_tags" ]]; then
      query=$(printf '%s' "$normalized_tags" | tr ' ' ',' | sed 's/#//g; s/,.*//')
    fi
  fi

  printf '%s\t%s\n' "$query" "$normalized_tags"
}

link_personal_context() {
  local raw="${1:?query or tags required}"
  local limit="${2:-10}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=10
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=10
  fi

  local query normalized_tags
  IFS=$'\t' read -r query normalized_tags < <(context_terms_from_input "$raw")

  local notes_output reminders_output events_output
  if [[ -n "$normalized_tags" ]]; then
    notes_output=$(find_tagged_notes "$normalized_tags" "$limit" 2>/dev/null || true)
  else
    notes_output=$(search_notes "$query" "$limit" 2>/dev/null || true)
  fi

  reminders_output=""
  if [[ -n "$normalized_tags" ]]; then
    local tag
    for tag in $normalized_tags; do
      tag=${tag#\#}
      local chunk
      chunk=$(bash "$SCRIPT_DIR/apple-reminders.sh" search-tag "$tag" --json 2>/dev/null || true)
      if [[ -n "$chunk" && "$chunk" != "[]" ]]; then
        reminders_output+="$chunk"$'\n'
      fi
    done
  fi
  if [[ -z "$reminders_output" ]]; then
    reminders_output=$(bash "$SCRIPT_DIR/apple-reminders.sh" search "$query" --json 2>/dev/null || true)
  fi

  events_output=$(bash "$SCRIPT_DIR/apple-calendar.sh" search "$query" --json 2>/dev/null || true)

  if [[ $want_json -eq 1 ]]; then
    LINK_CONTEXT_RAW="$raw" \
    LINK_CONTEXT_TAGS="$normalized_tags" \
    LINK_CONTEXT_NOTES="$notes_output" \
    LINK_CONTEXT_REMINDERS="$reminders_output" \
    LINK_CONTEXT_EVENTS="$events_output" \
    python3 -c 'import json, os
raw = os.environ.get("LINK_CONTEXT_RAW", "")
tags = os.environ.get("LINK_CONTEXT_TAGS", "")
notes_raw = os.environ.get("LINK_CONTEXT_NOTES", "")
reminders_raw = os.environ.get("LINK_CONTEXT_REMINDERS", "")
events_raw = os.environ.get("LINK_CONTEXT_EVENTS", "")

notes = []
for line in notes_raw.splitlines():
    line = line.strip()
    if not line or line.startswith("(no matches for:"):
        continue
    parts = line.split("\t")
    if len(parts) >= 3:
        notes.append({"folder": parts[0], "modified_at": parts[1], "title": parts[2]})

reminders = []
seen = set()
for line in reminders_raw.splitlines():
    line = line.strip()
    if not line or line == "[]":
        continue
    try:
        data = json.loads(line)
    except Exception:
        continue
    if isinstance(data, dict):
        data = [data]
    for item in data:
        key = (item.get("list"), item.get("title"), item.get("due_date"))
        if key in seen:
            continue
        seen.add(key)
        reminders.append(item)

try:
    events = json.loads(events_raw or "[]")
except Exception:
    events = []

payload = {
    "query": raw,
    "tags": tags.split() if tags else [],
    "notes": notes,
    "reminders": reminders[:10],
    "events": events[:10],
}
print(json.dumps(payload, ensure_ascii=True))'
    return
  fi

  printf 'Context: %s\n' "$raw"
  if [[ -n "$normalized_tags" ]]; then
    printf 'Tags: %s\n' "$normalized_tags"
  fi
  printf '\n[Notes]\n'
  if [[ -n "$notes_output" && "$notes_output" != "(no matches for: ${normalized_tags})" && "$notes_output" != "(no matches for: ${query})" ]]; then
    printf '%s\n' "$notes_output" | awk 'NF' | head -n "$limit"
  else
    printf 'No matching notes\n'
  fi

  printf '\n[Reminders]\n'
  if [[ -n "$reminders_output" ]]; then
    printf '%s\n' "$reminders_output" | python3 -c 'import json,sys
seen=set()
count=0
for line in sys.stdin:
    line=line.strip()
    if not line or line == "[]":
        continue
    try:
        data=json.loads(line)
    except Exception:
        continue
    if isinstance(data, dict):
        data=[data]
    for item in data:
        key=(item.get("list"), item.get("title"))
        if key in seen:
            continue
        seen.add(key)
        print(f"{item.get('"'"'list'"'"','"'"''"'"')}\t{item.get('"'"'title'"'"','"'"''"'"')}\t{item.get('"'"'due_date'"'"','"'"''"'"')}")
        count += 1
        if count >= 10:
            raise SystemExit'
  else
    printf 'No matching reminders\n'
  fi

  printf '\n[Events]\n'
  if [[ -n "$events_output" && "$events_output" != "[]" ]]; then
    printf '%s\n' "$events_output" | python3 -c 'import json,sys
try:
    data=json.loads(sys.stdin.read() or "[]")
except Exception:
    data=[]
for item in data[:10]:
    print(f"{item.get('"'"'calendar'"'"','"'"''"'"')}\t{item.get('"'"'start'"'"','"'"''"'"')}\t{item.get('"'"'title'"'"','"'"''"'"')}")'
  else
    printf 'No matching events\n'
  fi
}

improve_tag_cluster() {
  local raw_tags="${1:?tags required}"
  local limit="${2:-20}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    limit=20
  fi
  if [[ "$limit" -le 0 ]]; then
    limit=20
  fi

  local normalized_tags
  normalized_tags=$(normalize_tag_list "$raw_tags") || die "at least one valid tag is required"
  local matches
  matches=$(find_tagged_notes "$normalized_tags" "$limit" 2>/dev/null || true)

  CLUSTER_TAGS="$normalized_tags" \
  CLUSTER_MATCHES="$matches" \
  CLUSTER_SCRIPT="$0" \
  WANT_JSON="$want_json" \
  python3 -c 'import json, os, subprocess
tags = os.environ.get("CLUSTER_TAGS", "")
matches = os.environ.get("CLUSTER_MATCHES", "")
script = os.environ.get("CLUSTER_SCRIPT", "")

notes = []
for line in matches.splitlines():
    line = line.strip()
    if not line or line.startswith("(no matches for:"):
        continue
    parts = line.split("\t")
    if len(parts) >= 3:
        notes.append({"folder": parts[0], "modified_at": parts[1], "title": parts[2]})

for note in notes:
    try:
        out = subprocess.check_output([script, "suggest-tags", note["title"], note["title"]], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        out = ""
    suggested = [line.split("\t", 1)[0] for line in out.splitlines() if line.strip()]
    note["suggested_tags"] = suggested[:5]
    existing = set(tags.split())
    suggested_set = set(suggested)
    note["missing_suggested_tags"] = sorted(suggested_set - existing)
    note["archive_candidate"] = note["folder"].lower() == "archive"

summary = {
    "cluster_tags": tags.split(),
    "note_count": len(notes),
    "notes": notes,
    "retag_candidates": [n for n in notes if n["missing_suggested_tags"]],
    "archive_candidates": [n for n in notes if n["archive_candidate"]],
}

if os.environ.get("WANT_JSON") == "1":
    print(json.dumps(summary, ensure_ascii=True))
else:
    print(f"Cluster: {tags}")
    print(f"Notes: {len(notes)}")
    print("\n[Review]")
    if not notes:
        print("No matching notes")
    for note in notes:
        missing = ", ".join(note["missing_suggested_tags"])
        status = []
        if missing:
            status.append(f"retag -> {missing}")
        if note["archive_candidate"]:
            status.append("already in Archive")
        detail = "; ".join(status) if status else "looks consistent"
        print(f"{note['modified_at']}\t{note['title']}\t{detail}")

    print("\n[Actions]")
    if summary["retag_candidates"]:
        for note in summary["retag_candidates"][:10]:
            print(f"re-tag-note \"{note['title']}\" \"{tags.replace('#', '').replace(' ', ',')}\"")
    else:
        print("No retag suggestions")
'
}

read_tagged_note() {
  local normalized_tags
  normalized_tags=$(normalize_tag_list "${1:?tags required}") || die "at least one valid tag is required"
  local note_title
  note_title=$(escape_as_string "${2:?title required}")
  local tag_list
  tag_list=$(tags_to_applescript_list "$normalized_tags")

  local output
  if ! output=$(osascript -e "
    set tagList to ${tag_list}
    set targetTitle to \"${note_title}\"
    tell application \"Notes\"
      set targetNote to missing value
      repeat with f in folders
        repeat with n in notes of f
          if name of n is targetTitle then
            set noteText to plaintext of n
            if my noteHasAllTags(noteText, tagList) then
              set targetNote to n
              exit repeat
            end if
          end if
        end repeat
        if targetNote is not missing value then exit repeat
      end repeat

      if targetNote is missing value then
        error \"Tagged note not found: ${note_title}\"
      end if

      return plaintext of targetNote
    end tell

    on noteHasAllTags(noteText, tagList)
      repeat with currentTag in tagList
        if noteText does not contain (contents of currentTag) then
          return false
        end if
      end repeat
      return true
    end noteHasAllTags
  " 2>&1); then
    echo "(error: could not read tagged note; check tags and note title)" >&2
    return 1
  fi

  printf '%s\n' "$output"
}

write_tagged_note() {
  resolve_write_tagged_args "$@"

  local normalized_tags=""
  if [[ -n "${WRITE_TAGGED_TAGS:-}" ]]; then
    normalized_tags=$(normalize_tag_list "$WRITE_TAGGED_TAGS") || die "at least one valid tag is required"
  fi

  local note_title_raw="$WRITE_TAGGED_TITLE"
  local note_title
  note_title=$(escape_as_string "$note_title_raw")
  local note_body="$WRITE_TAGGED_BODY"
  local tag_html
  tag_html=$(build_tag_html "$normalized_tags")
  local tag_list
  tag_list=$(tags_to_applescript_list "$normalized_tags")

  local tmpfile
  tmpfile=$(mktemp /tmp/apple-notes-XXXXXX.html)
  printf '%s' "<h1>${note_title_raw}</h1>${tag_html}${note_body}" > "$tmpfile"

  local output
  if ! output=$(osascript \
    -e "set bodyFile to POSIX file \"${tmpfile}\"" \
    -e 'set noteBody to read bodyFile as «class utf8»' \
    -e "set tagList to ${tag_list}" \
    -e "set targetTitle to \"${note_title}\"" \
    -e 'tell application "Notes"' \
    -e '  set targetNote to missing value' \
    -e '  repeat with f in folders' \
    -e '    repeat with n in notes of f' \
    -e '      if name of n is targetTitle then' \
    -e '        set noteText to plaintext of n' \
    -e '        if (count of tagList) is 0 or my noteHasAllTags(noteText, tagList) then' \
    -e '          set targetNote to n' \
    -e '          exit repeat' \
    -e '        end if' \
    -e '      end if' \
    -e '    end repeat' \
    -e '    if targetNote is not missing value then exit repeat' \
    -e '  end repeat' \
    -e '  if targetNote is not missing value then' \
    -e '    set body of targetNote to noteBody' \
    -e '    return "Updated: " & targetTitle' \
    -e '  end if' \
    -e '  set targetFolder to first folder' \
    -e '  make new note at targetFolder with properties {name:targetTitle, body:noteBody}' \
    -e '  return "Created: " & targetTitle' \
    -e 'end tell' \
    -e 'on noteHasAllTags(noteText, tagList)' \
    -e '  repeat with currentTag in tagList' \
    -e '    if noteText does not contain (contents of currentTag) then return false' \
    -e '  end repeat' \
    -e '  return true' \
    -e 'end noteHasAllTags' 2>&1); then
    rm -f "$tmpfile"
    echo "(error: could not write tagged note - ${output})" >&2
    return 1
  fi

  rm -f "$tmpfile"
  if [[ -n "$normalized_tags" ]]; then
    printf '%s\nTags: %s\n' "$output" "$normalized_tags"
  else
    printf '%s\n' "$output"
  fi
}

ensure_archive_folder() {
  local archive_folder="${1:-Archive}"
  local escaped_archive
  escaped_archive=$(escape_as_string "$archive_folder")
  if ! osascript -e "tell application \"Notes\" to return name of folder \"${escaped_archive}\"" >/dev/null 2>&1; then
    osascript -e "tell application \"Notes\" to make new folder with properties {name:\"${escaped_archive}\"}" >/dev/null 2>&1 || {
      echo "(error: could not access or create archive folder '${archive_folder}')" >&2
      return 1
    }
  fi
}

archive_note() {
  local source_folder="${1:?folder required}"
  local note_title="${2:?title required}"
  local archive_folder="${3:-Archive}"
  local content

  ensure_archive_folder "$archive_folder" || return 1
  content=$(read_note "$source_folder" "$note_title") || return 1
  write_note "$archive_folder" "$note_title" "<pre>$(escape_html "$content")</pre>" >/dev/null || return 1
  delete_note "$source_folder" "$note_title" >/dev/null || return 1
  printf 'Archived: %s -> %s\n' "$note_title" "$archive_folder"
}

archive_tagged_note() {
  local normalized_tags
  normalized_tags=$(normalize_tag_list "${1:?tags required}") || die "at least one valid tag is required"
  local note_title="${2:?title required}"
  local archive_folder="${3:-Archive}"
  local content

  ensure_archive_folder "$archive_folder" || return 1
  content=$(read_tagged_note "$normalized_tags" "$note_title") || return 1
  write_note "$archive_folder" "$note_title" "<p>${normalized_tags}</p><pre>$(escape_html "$content")</pre>" >/dev/null || return 1
  delete_tagged_note "$normalized_tags" "$note_title" >/dev/null || return 1
  printf 'Archived tagged note: %s -> %s\n' "$note_title" "$archive_folder"
}

retag_note() {
  local note_title="${1:?title required}"
  local existing_tags="${2-}"
  local source_folder source_title plaintext body_text suggested_tags

  if [[ -n "$existing_tags" ]]; then
    IFS=$'\t' read -r source_folder source_title < <(locate_tagged_note "$existing_tags" "$note_title") || {
      echo "(error: could not find tagged note for: $note_title)" >&2
      return 1
    }
    plaintext=$(read_tagged_note "$existing_tags" "$source_title") || return 1
  else
    IFS=$'\t' read -r source_folder source_title < <(locate_note_by_title "$note_title") || {
      echo "(error: could not locate note by title: $note_title)" >&2
      return 1
    }
    plaintext=$(read_note "$source_folder" "$source_title") || return 1
  fi

  body_text=$(prepare_retag_plaintext "$source_title" "$plaintext")
  suggested_tags=$(suggest_tags "$source_title" "$body_text" | awk -F'\t' '{print $1}' | head -n 5 | paste -sd, -)

  if [[ -z "$suggested_tags" ]]; then
    if [[ -n "$existing_tags" ]]; then
      suggested_tags="$existing_tags"
    else
      echo "(error: could not suggest replacement tags)" >&2
      return 1
    fi
  fi

  write_tagged_note "$suggested_tags" "$source_title" "<pre>$(escape_html "$body_text")</pre>" >/dev/null || return 1

  if [[ -n "$existing_tags" ]]; then
    delete_tagged_note "$existing_tags" "$source_title" >/dev/null || return 1
  else
    delete_note "$source_folder" "$source_title" >/dev/null || return 1
  fi

  printf 'Re-tagged: %s\nTags: %s\n' "$source_title" "$(normalize_tag_list "$suggested_tags")"
}

append_tagged_note() {
  local normalized_tags
  normalized_tags=$(normalize_tag_list "${1:?tags required}") || die "at least one valid tag is required"
  local note_title
  note_title=$(escape_as_string "${2:?title required}")
  local content="$3"
  local tag_list
  tag_list=$(tags_to_applescript_list "$normalized_tags")

  local tmpfile
  tmpfile=$(mktemp /tmp/apple-notes-XXXXXX.html)
  printf '%s' "$content" > "$tmpfile"

  local output
  if ! output=$(osascript \
    -e "set contentFile to POSIX file \"${tmpfile}\"" \
    -e 'set appendContent to read contentFile as «class utf8»' \
    -e "set tagList to ${tag_list}" \
    -e "set targetTitle to \"${note_title}\"" \
    -e 'tell application "Notes"' \
    -e '  set targetNote to missing value' \
    -e '  repeat with f in folders' \
    -e '    repeat with n in notes of f' \
    -e '      if name of n is targetTitle then' \
    -e '        set noteText to plaintext of n' \
    -e '        if my noteHasAllTags(noteText, tagList) then' \
    -e '          set targetNote to n' \
    -e '          exit repeat' \
    -e '        end if' \
    -e '      end if' \
    -e '    end repeat' \
    -e '    if targetNote is not missing value then exit repeat' \
    -e '  end repeat' \
    -e '  if targetNote is missing value then error "Tagged note not found"' \
    -e '  set currentBody to body of targetNote' \
    -e '  set body of targetNote to currentBody & "<br>" & appendContent' \
    -e '  return "Appended to: " & targetTitle' \
    -e 'end tell' \
    -e 'on noteHasAllTags(noteText, tagList)' \
    -e '  repeat with currentTag in tagList' \
    -e '    if noteText does not contain (contents of currentTag) then return false' \
    -e '  end repeat' \
    -e '  return true' \
    -e 'end noteHasAllTags' 2>&1); then
    rm -f "$tmpfile"
    echo "(error: could not append to tagged note; check tags and note title)" >&2
    return 1
  fi

  rm -f "$tmpfile"
  printf '%s\n' "$output"
}

delete_tagged_note() {
  local normalized_tags
  normalized_tags=$(normalize_tag_list "${1:?tags required}") || die "at least one valid tag is required"
  local note_title
  note_title=$(escape_as_string "${2:?title required}")
  local tag_list
  tag_list=$(tags_to_applescript_list "$normalized_tags")

  local output
  if ! output=$(osascript -e "
    set tagList to ${tag_list}
    set targetTitle to \"${note_title}\"
    tell application \"Notes\"
      set targetNote to missing value
      repeat with f in folders
        repeat with n in notes of f
          if name of n is targetTitle then
            set noteText to plaintext of n
            if my noteHasAllTags(noteText, tagList) then
              set targetNote to n
              exit repeat
            end if
          end if
        end repeat
        if targetNote is not missing value then exit repeat
      end repeat

      if targetNote is missing value then
        error \"Tagged note not found: ${note_title}\"
      end if

      delete targetNote
      return \"Deleted: ${note_title}\"
    end tell

    on noteHasAllTags(noteText, tagList)
      repeat with currentTag in tagList
        if noteText does not contain (contents of currentTag) then
          return false
        end if
      end repeat
      return true
    end noteHasAllTags
  " 2>&1); then
    echo "(error: could not delete tagged note; check tags and note title)" >&2
    return 1
  fi

  printf '%s\n' "$output"
}

delete_note() {
  local folder_name
  folder_name=$(escape_as_string "$1")
  local note_title
  note_title=$(escape_as_string "$2")
  
  local output
  if ! output=$(osascript -e "
    tell application \"Notes\"
      try
        set targetFolder to folder \"${folder_name}\"
        set targetNote to first note of targetFolder whose name is \"${note_title}\"
      on error
        error \"Note not found: ${note_title} in ${folder_name}\"
      end try
      delete targetNote
      return \"Deleted: ${note_title}\"
    end tell
  " 2>&1); then
    echo "(error: could not delete note; check folder and note name)" >&2
    return 1
  fi
  printf '%s\n' "$output"
}

ensure_assistant_folder() {
  printf '%s\n' "Using hashtags for assistant notes: ${ASSISTANT_COLLECTION_TAG}"
}

# --- Assistant-specific sync commands ---
# These use hashtags in Apple Notes that sync via iCloud
# allowing the assistant to persist state across all Apple devices
# read-* commands extract ONLY the JSON payload for machine parsing

sync_context() {
  local json_data="$1"
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M")
  local html_body="<p><b>Last Updated:</b> ${timestamp}</p><p><b>Context:</b></p><pre id=\"json-data\">BEGIN_JSON
${json_data}
END_JSON</pre>"

  write_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_CONTEXT_TAG}" "$ASSISTANT_CONTEXT_NOTE_TITLE" "$html_body"
}

read_context() {
  local plaintext
  if ! plaintext=$(read_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_CONTEXT_TAG}" "$ASSISTANT_CONTEXT_NOTE_TITLE" 2>/dev/null); then
    if ! plaintext=$(read_note "✱ AI Assistant" "$ASSISTANT_CONTEXT_NOTE_TITLE" 2>/dev/null); then
      echo "{}"
      return
    fi
  fi

  local json
  json=$(printf '%s\n' "$plaintext" | extract_json_between_markers || true)
  if [ -n "$json" ]; then
    printf '%s\n' "$json"
    return
  fi

  # Backward-compatible fallback (older notes may contain single-line JSON)
  printf '%s\n' "$plaintext" | awk '/Context:/,0' | sed '1d' | grep -E '^\s*[\{\[]' | head -1 || echo "{}"
}

sync_profile() {
  local json_data="$1"
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M")
  local html_body="<p><b>Last Updated:</b> ${timestamp}</p><p><b>Profile:</b></p><pre id=\"json-data\">BEGIN_JSON
${json_data}
END_JSON</pre>"

  write_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_PROFILE_TAG}" "$ASSISTANT_PROFILE_NOTE_TITLE" "$html_body"
}

read_profile() {
  local plaintext
  if ! plaintext=$(read_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_PROFILE_TAG}" "$ASSISTANT_PROFILE_NOTE_TITLE" 2>/dev/null); then
    if ! plaintext=$(read_note "✱ AI Assistant" "$ASSISTANT_PROFILE_NOTE_TITLE" 2>/dev/null); then
      echo "{}"
      return
    fi
  fi

  local json
  json=$(printf '%s\n' "$plaintext" | extract_json_between_markers || true)
  if [ -n "$json" ]; then
    printf '%s\n' "$json"
    return
  fi

  # Backward-compatible fallback (older notes may contain single-line JSON)
  printf '%s\n' "$plaintext" | awk '/Profile:/,0' | sed '1d' | grep -E '^\s*[\{\[]' | head -1 || echo "{}"
}

sync_tasks() {
  local json_data="$1"
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M")
  local html_body="<p><b>Last Updated:</b> ${timestamp}</p><p><b>Active Tasks:</b></p><pre id=\"json-data\">BEGIN_JSON
${json_data}
END_JSON</pre>"

  write_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_TASKS_TAG}" "$ASSISTANT_TASKS_NOTE_TITLE" "$html_body"
}

read_tasks() {
  local plaintext
  if ! plaintext=$(read_tagged_note "${ASSISTANT_COLLECTION_TAG} ${ASSISTANT_TASKS_TAG}" "$ASSISTANT_TASKS_NOTE_TITLE" 2>/dev/null); then
    if ! plaintext=$(read_note "✱ AI Assistant" "$ASSISTANT_TASKS_NOTE_TITLE" 2>/dev/null); then
      echo "[]"
      return
    fi
  fi

  local json
  json=$(printf '%s\n' "$plaintext" | extract_json_between_markers || true)
  if [ -n "$json" ]; then
    printf '%s\n' "$json"
    return
  fi

  # Backward-compatible fallback (older notes may contain single-line JSON)
  printf '%s\n' "$plaintext" | awk '/Active Tasks:/,0' | sed '1d' | grep -E '^\s*[\{\[]' | head -1 || echo "[]"
}

case "${1:-help}" in
  folders)        list_folders ;;
  list)           list_notes_in_folder "${2:?folder required}" ;;
  read)           read_note "${2:?folder required}" "${3:?title required}" ;;
  write)          write_note "${2:?folder required}" "${3:?title required}" "${4:?body required}" ;;
  append)         append_to_note "${2:?folder required}" "${3:?title required}" "${4:?content required}" ;;
  search)         search_notes "${2-}" "${3-}" ;;
  search-tag)     search_notes_tag "${2:?tag required}" "${3-}" ;;
  list-tags)      list_tags "${2-}" ;;
  list-untagged)  list_untagged_notes "${2-}" ;;
  find-tagged)    find_tagged_notes "${2:?tags required}" "${3-}" ;;
  suggest-tags)   suggest_tags "${2:?title required}" "${3-}" ;;
  read-tagged)    read_tagged_note "${2:?tags required}" "${3:?title required}" ;;
  write-tagged)   shift; write_tagged_note "$@" ;;
  append-tagged)  append_tagged_note "${2:?tags required}" "${3:?title required}" "${4:?content required}" ;;
  delete-tagged)  delete_tagged_note "${2:?tags required}" "${3:?title required}" ;;
  archive-note)   archive_note "${2:?folder required}" "${3:?title required}" "${4-}" ;;
  archive-tagged) archive_tagged_note "${2:?tags required}" "${3:?title required}" "${4-}" ;;
  re-tag-note)    retag_note "${2:?title required}" "${3-}" ;;
  link-personal-context) link_personal_context "${2:?query or tags required}" "${3-}" ;;
  improve-tag-cluster) improve_tag_cluster "${2:?tags required}" "${3-}" ;;
  delete)         delete_note "${2:?folder required}" "${3:?title required}" ;;
  sync-context)   sync_context "${2:?json required}" ;;
  read-context)   read_context ;;
  sync-profile)   sync_profile "${2:?json required}" ;;
  read-profile)   read_profile ;;
  sync-tasks)     sync_tasks "${2:?json required}" ;;
  read-tasks)     read_tasks ;;
  ensure-folder)  ensure_assistant_folder ;;
  help|*)         usage ;;
esac
