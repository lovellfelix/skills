#!/usr/bin/env bash
set -euo pipefail

dry_run=false
agents_home="${AGENTS_HOME:-$HOME/.agents}"
default_db_path="$agents_home/memory/session.db"
legacy_db_path="$HOME/.opencode/sessions/session.db"
db_path="${SESSION_DB:-}"
session_id=""
label=""

usage() {
  cat <<'EOF'
promote-session-memory.sh - promote MCP session contexts to durable ~/.agents/memory artifacts

Usage:
  ./hacks/promote-session-memory.sh --session-id <id> [--label <name>] [--db <path>] [--agents-home <path>] [--dry-run]

Examples:
  ./hacks/promote-session-memory.sh --session-id opencode-2026-03-20
  ./hacks/promote-session-memory.sh --session-id sprint-42 --label auth-refactor
  ./hacks/promote-session-memory.sh --session-id hotfix --db "$HOME/.agents/memory/session.db"

Output:
  ~/.agents/memory/promoted/<timestamp>-<session>.json
  ~/.agents/memory/promoted/<timestamp>-<session>.md

Next step:
  Update durable project + handoff files:
  ~/.agents/memory/projects/<project>/current.md
  ~/.agents/memory/handoffs/YYYY/MM/<timestamp>-<project>-<topic>.md

Safety:
  - Never replaces ~/.agents/memory wholesale.
  - Only creates missing directories/files inside ~/.agents/memory.
  - Fails if target paths exist as non-directories.
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
    lowered="session"
  fi

  printf '%s' "$lowered"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)
      [[ $# -ge 2 ]] || die "Missing value for --session-id"
      session_id="$2"
      shift 2
      ;;
    --label)
      [[ $# -ge 2 ]] || die "Missing value for --label"
      label="$2"
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

[[ -n "$session_id" ]] || die "--session-id is required"

resolve_db_path
if [[ ! -f "$db_path" ]]; then
  if [[ "$dry_run" == "true" ]]; then
    warn "Database not found (dry-run continues): $db_path"
  else
    die "Database not found: $db_path"
  fi
fi

memory_dir="$agents_home/memory"
promoted_dir="$memory_dir/promoted"

ensure_dir "$agents_home"
ensure_dir "$memory_dir"
ensure_dir "$promoted_dir"

ts="$(date +%Y%m%d%H%M%S)"
session_slug="$(slugify "$session_id")"
base_name="$ts-$session_slug"
if [[ -n "$label" ]]; then
  base_name+="-$(slugify "$label")"
fi

json_path="$promoted_dir/$base_name.json"
md_path="$promoted_dir/$base_name.md"

if [[ "$dry_run" == "true" ]]; then
  log "DRY RUN: Promote session '$session_id' from $db_path"
  log "DRY RUN: write $json_path"
  log "DRY RUN: write $md_path"
  exit 0
fi

umask 077

python3 - "$db_path" "$session_id" "$json_path" "$md_path" <<'PY'
import json
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

db_path, session_id, json_path, md_path = sys.argv[1:5]

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
rows = conn.execute(
    """
    SELECT session_id, context_type, key, value, metadata, updated_at
    FROM session_contexts
    WHERE session_id = ?
    ORDER BY updated_at DESC
    """,
    (session_id,),
).fetchall()
conn.close()

if not rows:
    # No session_contexts rows for this session_id — treat as non-fatal.
    # Some sessions may store data under other tables (tasks/interactions).
    # Make promotion tolerant and skip rather than error, so batch runs continue.
    print(f"WARN: no session_contexts rows found for session_id={session_id}", file=sys.stderr)
    raise SystemExit(0)

records = [dict(row) for row in rows]
record_count = len(records)
types = sorted({record.get("context_type") or "unknown" for record in records})
latest_updated = records[0].get("updated_at")

export_payload = {
    "schema_version": 1,
    "promoted_at": datetime.now(timezone.utc).isoformat(),
    "source": {
        "db_path": db_path,
        "session_id": session_id,
    },
    "summary": {
        "record_count": record_count,
        "context_types": types,
        "latest_updated_at": latest_updated,
    },
    "session_contexts": records,
}

json_file = Path(json_path)
json_file.write_text(json.dumps(export_payload, indent=2) + "\n", encoding="utf-8")

lines = [
    "---",
    f"artifact_type: promoted-session-summary",
    f"session_id: {session_id}",
    f"source_db: {db_path}",
    f"record_count: {record_count}",
    f"promoted_at: {export_payload['promoted_at']}",
    f"context_types: [{', '.join(json.dumps(item) for item in types)}]",
    "---",
    "",
    "# Session Memory Promotion",
    "",
    f"- Session ID: `{session_id}`",
    f"- Promoted at: `{export_payload['promoted_at']}`",
    f"- Source DB: `{db_path}`",
    f"- Records: `{record_count}`",
    f"- Context types: `{', '.join(types)}`",
]

if latest_updated:
    lines.append(f"- Latest context update: `{latest_updated}`")

lines.extend([
    "",
    "## Recent Contexts",
    "",
])

for record in records[:20]:
    context_type = record.get("context_type") or "unknown"
    key = record.get("key") or "(no-key)"
    value = (record.get("value") or "").strip().replace("\n", " ")
    if len(value) > 180:
        value = value[:177] + "..."
    updated_at = record.get("updated_at") or "unknown"
    lines.append(f"- `{updated_at}` [{context_type}] `{key}` - {value}")

if record_count > 20:
    lines.append("")
    lines.append(f"_Truncated to the 20 most recent records out of {record_count}._")

Path(md_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

log "Promoted session memory to durable artifacts:"
log "- $json_path"
log "- $md_path"
log "Next: sync project state + handoff packet under ~/.agents/memory/projects and ~/.agents/memory/handoffs"
