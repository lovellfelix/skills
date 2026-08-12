#!/usr/bin/env bash
# smem.sh — Session memory CLI for contexts where the MCP server is unavailable.
# Reads/writes session.db directly via sqlite3. No server required.
#
# Usage:
#   smem.sh list [session_id]           — recent context records
#   smem.sh get <key> [session_id]      — read a context value by key
#   smem.sh set <type> <key> <value> [session_id]  — write/upsert a record
#   smem.sh tasks [workflow_id]         — list workflow tasks
#   smem.sh prefs                       — show user preferences
#   smem.sh conventions [project_id]    — show project conventions
#   smem.sh search <query> [session_id] — full-text search
#   smem.sh dump [session_id]           — all records for a session
#   smem.sh sessions                    — list known session IDs
#   smem.sh help                        — this message

set -euo pipefail

DB="${SESSION_DB:-${HOME}/.agents/memory/session.db}"
DEFAULT_SESSION="${SMEM_SESSION:-default}"

die() { echo "smem: error: $*" >&2; exit 1; }
need_sqlite() { command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 not found in PATH"; }
need_db() { [[ -f "$DB" ]] || die "session.db not found at $DB (set SESSION_DB env to override)"; }

q() { sqlite3 -column -header "$DB" "$@"; }
qraw() { sqlite3 "$DB" "$@"; }

# ─── format helpers ───────────────────────────────────────────────────────────
trunc() {
  local str="$1" max="${2:-80}"
  if (( ${#str} > max )); then printf '%s…' "${str:0:$((max-1))}"; else printf '%s' "$str"; fi
}

# ─── subcommands ──────────────────────────────────────────────────────────────

cmd_list() {
  local session="${1:-}"
  local where=""
  [[ -n "$session" ]] && where="WHERE session_id = '${session//\'/\'\'}'"
  q "SELECT session_id, context_type, key,
        substr(value,1,80) AS value_preview,
        updated_at
     FROM session_contexts
     ${where}
     ORDER BY updated_at DESC
     LIMIT 30;"
}

cmd_get() {
  local key="${1:?usage: smem get <key> [session_id]}"
  local session="${2:-$DEFAULT_SESSION}"
  qraw "SELECT value FROM session_contexts
        WHERE session_id = '${session//\'/\'\'}' AND key = '${key//\'/\'\'}'
        ORDER BY updated_at DESC LIMIT 1;" \
    | head -1
}

cmd_set() {
  local type="${1:?usage: smem set <type> <key> <value> [session_id]}"
  local key="${2:?missing key}"
  local value="${3:?missing value}"
  local session="${4:-$DEFAULT_SESSION}"
  local ts; ts="$(date -u +"%Y-%m-%d %H:%M:%S")"
  qraw "INSERT INTO session_contexts (session_id, context_type, key, value, created_at, updated_at)
        VALUES ('${session//\'/\'\'}', '${type//\'/\'\'}', '${key//\'/\'\'}', '${value//\'/\'\'}', '${ts}', '${ts}')
        ON CONFLICT(session_id, context_type, key)
        DO UPDATE SET value=excluded.value, updated_at='${ts}';"
  echo "stored: ${session}/${type}/${key}"
}

cmd_tasks() {
  local workflow="${1:-}"
  local where=""
  [[ -n "$workflow" ]] && where="WHERE workflow_id = '${workflow//\'/\'\'}'"
  q "SELECT id,
        substr(title,1,50) AS title,
        state,
        priority,
        workflow_id,
        substr(created_at,1,16) AS created
     FROM tasks
     ${where}
     ORDER BY
       CASE state
         WHEN 'in_progress' THEN 0
         WHEN 'queued'      THEN 1
         WHEN 'blocked'     THEN 2
         WHEN 'failed'      THEN 3
         ELSE 4 END,
       priority ASC,
       id ASC
     LIMIT 50;"
}

cmd_prefs() {
  q "SELECT category, preference_key, preference_value,
        printf('%.2f', confidence) AS confidence,
        updated_at
     FROM user_preferences
     ORDER BY category, preference_key;"
}

cmd_conventions() {
  local project="${1:-}"
  local where=""
  [[ -n "$project" ]] && where="WHERE project_id = '${project//\'/\'\'}'"
  q "SELECT project_id, language, convention_type, convention_key,
        substr(convention_value,1,60) AS value_preview,
        updated_at
     FROM project_conventions
     ${where}
     ORDER BY project_id, language, convention_type;"
}

cmd_search() {
  local query="${1:?usage: smem search <query> [session_id]}"
  local session="${2:-}"
  local session_filter=""
  [[ -n "$session" ]] && session_filter="AND sc.session_id = '${session//\'/\'\'}'"
  # FTS search if available, else LIKE fallback
  local fts_count
  fts_count=$(qraw "SELECT count(*) FROM sqlite_master WHERE name='session_contexts_fts';" 2>/dev/null || echo 0)
  if (( fts_count > 0 )); then
    q "SELECT sc.session_id, sc.context_type, sc.key,
          substr(sc.value,1,80) AS value_preview,
          sc.updated_at
       FROM session_contexts sc
       JOIN session_contexts_fts fts ON sc.id = fts.rowid
       WHERE fts.session_contexts_fts MATCH '${query//\'/\'\'}'
         ${session_filter}
       ORDER BY sc.updated_at DESC
       LIMIT 20;"
  else
    q "SELECT session_id, context_type, key,
          substr(value,1,80) AS value_preview,
          updated_at
       FROM session_contexts
       WHERE (key LIKE '%${query//\'/\'\'}%' OR value LIKE '%${query//\'/\'\'}%')
         ${session_filter}
       ORDER BY updated_at DESC
       LIMIT 20;"
  fi
}

cmd_dump() {
  local session="${1:-$DEFAULT_SESSION}"
  q "SELECT context_type, key, value, updated_at
     FROM session_contexts
     WHERE session_id = '${session//\'/\'\'}'
     ORDER BY context_type, updated_at DESC;"
}

cmd_sessions() {
  q "SELECT session_id,
        count(*) AS records,
        max(updated_at) AS last_updated
     FROM session_contexts
     GROUP BY session_id
     ORDER BY last_updated DESC
     LIMIT 30;"
}

cmd_help() {
  sed -n '/^# smem/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# /  /'
  exit 0
}

# ─── dispatch ─────────────────────────────────────────────────────────────────

need_sqlite
need_db

cmd="${1:-help}"
shift || true

case "$cmd" in
  list)         cmd_list "$@" ;;
  get)          cmd_get "$@" ;;
  set)          cmd_set "$@" ;;
  tasks)        cmd_tasks "$@" ;;
  prefs)        cmd_prefs "$@" ;;
  conventions)  cmd_conventions "$@" ;;
  search)       cmd_search "$@" ;;
  dump)         cmd_dump "$@" ;;
  sessions)     cmd_sessions "$@" ;;
  help|-h|--help) cmd_help ;;
  *) die "unknown subcommand: ${cmd}. Run 'smem.sh help' for usage." ;;
esac
