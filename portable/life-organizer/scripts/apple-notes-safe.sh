#!/usr/bin/env bash
set -euo pipefail

# Safe wrapper for apple-notes.sh with better error handling
# This wrapper ensures Notes.app is available and provides clearer error messages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTES_SCRIPT="${SCRIPT_DIR}/apple-notes.sh"

# Check if Notes.app is available
check_notes_available() {
  if ! osascript -e 'tell application "Notes" to return name of account 1' >/dev/null 2>&1; then
    echo "(error: Notes.app not accessible - check System Settings > Privacy & Security > Automation)" >&2
    return 1
  fi
  return 0
}

# Ensure folder exists before any legacy folder-based operation
ensure_folder() {
  local folder="$1"
  if ! osascript -e "tell application \"Notes\" to return name of folder \"${folder}\"" >/dev/null 2>&1; then
    # Try to create it
    if ! osascript -e "tell application \"Notes\" to make new folder with properties {name:\"${folder}\"}" >/dev/null 2>&1; then
      echo "(error: could not access or create folder '${folder}')" >&2
      return 1
    fi
  fi
  return 0
}

# Main command routing
case "${1:-help}" in
  sync-context|sync-profile|sync-tasks)
    # Tagged assistant note sync
    exec bash "$NOTES_SCRIPT" "$@"
    ;;
  
  read-context|read-profile|read-tasks)
    # Tagged assistant note reads
    exec bash "$NOTES_SCRIPT" "$@"
    ;;
  
  write|append|read|read-any|delete|list|search|search-tag|list-tags|list-untagged|find-tagged|suggest-tags|write-tagged|append-tagged|read-tagged|delete-tagged|archive-note|archive-tagged|re-tag-note|link-personal-context|improve-tag-cluster)
    # Generic commands - check Notes availability
    if ! check_notes_available; then
      exit 1
    fi
    cmd="$1"
    folder_arg="${2:-}"

    # Only auto-create folder for legacy folder-based write/append.
    if [[ "$cmd" == "write" || "$cmd" == "append" ]]; then
      if [ -n "$folder_arg" ]; then
        ensure_folder "$folder_arg" || exit 1
      fi
    fi

    if [[ "$cmd" == "read" ]]; then
      title_arg="${3:-}"
      if [ -z "$folder_arg" ] || [ -z "$title_arg" ]; then
        echo "(error: folder and title required)" >&2
        exit 1
      fi

      if ! out=$(bash "$NOTES_SCRIPT" read "$folder_arg" "$title_arg" 2>&1); then
        echo "$out" >&2
        echo "(hint: matching titles)" >&2
        bash "$NOTES_SCRIPT" search "$title_arg" 10 >&2 || true
        exit 1
      fi

      printf '%s\n' "$out"
      exit 0
    fi

    if [[ "$cmd" == "read-any" ]]; then
      title_arg="${2:-}"
      pick_arg="${3:-1}"
      if [ -z "$title_arg" ]; then
        echo "(error: title required)" >&2
        exit 1
      fi
      if ! [[ "$pick_arg" =~ ^[0-9]+$ ]]; then
        pick_arg=1
      fi
      if [[ "$pick_arg" -le 0 ]]; then
        pick_arg=1
      fi

      # Search for matching titles across all folders; pick Nth result (default: 1)
      matches=$(bash "$NOTES_SCRIPT" search "$title_arg" 20 2>/dev/null || true)
      if [[ -z "$matches" || "$matches" == \(no\ matches* ]]; then
        echo "(error: no matches for: $title_arg)" >&2
        exit 1
      fi

      # Format: <folder>\t<date>\t<title>
      folder=$(printf '%s\n' "$matches" | awk -F'\t' -v n="$pick_arg" 'NF>=3{c++; if(c==n){print $1; exit}}')
      title=$(printf '%s\n' "$matches" | awk -F'\t' -v n="$pick_arg" 'NF>=3{c++; if(c==n){print $3; exit}}')
      if [[ -z "$folder" || -z "$title" ]]; then
        echo "(error: could not resolve match)" >&2
        echo "(hint: candidates)" >&2
        printf '%s\n' "$matches" >&2
        exit 1
      fi

      exec bash "$NOTES_SCRIPT" read "$folder" "$title"
    fi

    exec bash "$NOTES_SCRIPT" "$@"
    ;;
  
  *)
    # Pass through all other commands (folders, search, etc.)
    exec bash "$NOTES_SCRIPT" "$@"
    ;;
esac
