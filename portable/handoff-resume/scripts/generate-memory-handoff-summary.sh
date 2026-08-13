#!/usr/bin/env bash
set -euo pipefail

dry_run=false
agents_home="${AGENTS_HOME:-$HOME/.agents}"
agents_home_explicit=false
default_db_path="$agents_home/memory/session.db"
legacy_db_path="$HOME/.opencode/sessions/session.db"
db_path="${SESSION_DB:-}"
project=""
topic="status"
session_id=""
summary_file=""
summary_text=""

usage() {
  cat <<'EOF'
generate-memory-handoff-summary.sh - write handoff summary to disk and MCP session memory

Usage:
  scripts/generate-memory-handoff-summary.sh --project <project-slug> --session-id <id> [options]

Options:
  --project <slug>       Project slug for durable handoff path
  --topic <topic>        Handoff topic slug (default: status)
  --session-id <id>      Session ID for MCP handoff record
  --summary-file <path>  Markdown file to use as summary body
  --summary <text>       One-line summary used when no --summary-file is provided
  --db <path>            SQLite DB path (default: ~/.agents/memory/session.db)
  --agents-home <path>   Base directory for ~/.agents replacement
  --dry-run              Show actions without writing

Examples:
  scripts/generate-memory-handoff-summary.sh --project dotfiles --session-id opencode-2026-03-20 --summary-file /tmp/handoff.md
  scripts/generate-memory-handoff-summary.sh --project dotfiles --session-id opencode-2026-03-20 --topic memory --summary "Updated memory model"
EOF
}

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_dir() {
  local dir=$1
  if [[ -e "$dir" && ! -d "$dir" ]]; then
    die "Path exists but is not a directory: $dir"
  fi

  if [[ -d "$dir" ]]; then
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log "DRY RUN: mkdir -p \"$dir\""
    return 0
  fi

  mkdir -p "$dir"
}

resolve_db_path() {
  if [[ -n "$db_path" ]]; then
    return
  fi

  if [[ -f "$default_db_path" ]]; then
    db_path="$default_db_path"
    return
  fi

  if [[ "$agents_home_explicit" == "true" ]]; then
    db_path="$default_db_path"
    return
  fi

  if [[ -f "$legacy_db_path" ]]; then
    db_path="$legacy_db_path"
    return
  fi

  db_path="$default_db_path"
}

slugify() {
  local input=$1
  local lowered
  lowered=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')
  lowered=${lowered// /-}
  lowered=${lowered//[^a-z0-9_.-]/-}
  lowered=${lowered#-}
  lowered=${lowered%-}

  if [[ -z "$lowered" ]]; then
    lowered="general"
  fi

  printf '%s' "$lowered"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || die "Missing value for --project"
      project="$2"
      shift 2
      ;;
    --topic)
      [[ $# -ge 2 ]] || die "Missing value for --topic"
      topic="$2"
      shift 2
      ;;
    --session-id)
      [[ $# -ge 2 ]] || die "Missing value for --session-id"
      session_id="$2"
      shift 2
      ;;
    --summary-file)
      [[ $# -ge 2 ]] || die "Missing value for --summary-file"
      summary_file="$2"
      shift 2
      ;;
    --summary)
      [[ $# -ge 2 ]] || die "Missing value for --summary"
      summary_text="$2"
      shift 2
      ;;
    --db)
      [[ $# -ge 2 ]] || die "Missing value for --db"
      db_path="$2"
      shift 2
      ;;
    --agents-home)
      [[ $# -ge 2 ]] || die "Missing value for --agents-home"
      agents_home="$2"
      agents_home_explicit=true
      default_db_path="$agents_home/memory/session.db"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$project" ]] || die "--project is required"
[[ -n "$session_id" ]] || die "--session-id is required"

project_slug=$(slugify "$project")
topic_slug=$(slugify "$topic")
ts=$(date +%Y%m%d%H%M%S)
year=$(date +%Y)
month=$(date +%m)

memory_dir="$agents_home/memory"
handoff_dir="$memory_dir/handoffs/$year/$month"
handoff_path="$handoff_dir/$ts-$project_slug-$topic_slug.md"

resolve_db_path
if [[ ! -f "$db_path" ]]; then
  if [[ "$dry_run" == "true" ]]; then
    warn "Database not found (dry-run continues): $db_path"
  else
    die "Database not found: $db_path"
  fi
fi

if [[ -n "$summary_file" && ! -f "$summary_file" ]]; then
  die "Summary file not found: $summary_file"
fi

if [[ -n "$summary_file" ]]; then
  summary_body=$(<"$summary_file")
elif [[ -n "$summary_text" ]]; then
  summary_body="$(printf '# Handoff\n\n- Summary: %s\n' "$summary_text")"
else
  summary_body="$(printf '# Handoff\n\n- Summary: <session summary>\n')"
fi

if [[ "$dry_run" == "true" ]]; then
  log "DRY RUN: write $handoff_path"
  log "DRY RUN: insert MCP handoff record in $db_path"
  exit 0
fi

ensure_dir "$agents_home"
ensure_dir "$memory_dir"
ensure_dir "$memory_dir/handoffs"
ensure_dir "$memory_dir/handoffs/$year"
ensure_dir "$handoff_dir"

if [[ -e "$handoff_path" ]]; then
  die "Handoff path already exists: $handoff_path"
fi

frontmatter=$(cat <<EOF
---
artifact_type: handoff
project: $project_slug
topic: $topic_slug
session_id: $session_id
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
source: generate-memory-handoff-summary
---
EOF
)

umask 077
printf '%s\n\n%s\n' "$frontmatter" "$summary_body" > "$handoff_path"

python3 - "$db_path" "$session_id" "$project_slug" "$topic_slug" "$handoff_path" "$ts" "$summary_body" <<'PY'
import json
import sqlite3
import sys

db_path, session_id, project_slug, topic_slug, handoff_path, ts, summary_body = sys.argv[1:8]

summary_text = " ".join(summary_body.strip().split())
if len(summary_text) > 500:
    summary_text = summary_text[:497] + "..."

context_key = f"handoff:{project_slug}:{ts}-{topic_slug}"
metadata = json.dumps(
    {
        "project": project_slug,
        "topic": topic_slug,
        "handoff_path": handoff_path,
        "timestamp": ts,
    }
)

conn = sqlite3.connect(db_path)
conn.execute(
    """
    INSERT INTO session_contexts (session_id, context_type, key, value, metadata, updated_at)
    VALUES (?, 'handoff', ?, ?, ?, CURRENT_TIMESTAMP)
    ON CONFLICT(session_id, context_type, key)
    DO UPDATE SET
      value = excluded.value,
      metadata = excluded.metadata,
      updated_at = CURRENT_TIMESTAMP
    """,
    (session_id, context_key, summary_text, metadata),
)
conn.commit()
conn.close()
PY

log "Created handoff summary artifacts:"
log "- Disk: $handoff_path"
log "- MCP: session_id=$session_id key=handoff:$project_slug:$ts-$topic_slug"
