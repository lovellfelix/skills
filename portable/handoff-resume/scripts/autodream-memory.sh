#!/usr/bin/env bash
set -euo pipefail

dry_run=false
apply_changes=false
single_session_mode=true
batch_reset=false
batch_max_seconds="170"
batch_max_sessions="8"
batch_state_file=""
batch_order="oldest"
suppress_result_lines=false
agents_home="${AGENTS_HOME:-$HOME/.agents}"
agents_home_explicit=false
default_db_path="$agents_home/memory/session.db"
legacy_db_path="$HOME/.opencode/sessions/session.db"
db_path="${SESSION_DB:-}"
db_path_explicit=false
session_id=""
session_pick_mode="stale"
stale_hours="24"
scan_limit="50"
list_session_candidates=false
project=""
topic="autodream"
label="autodream"
summary_override=""
summarizer_cmd="${AUTODREAM_SUMMARIZER_CMD:-}"
session_selection_note="unknown"
db_selection_note="unresolved"
run_mode="report-only"
promoted_artifact_state="not-requested"
project_scaffold_state="not-requested"
handoff_artifact_state="not-requested"
result_emitted=false
pref_count_before=""

# Promoted artifact retention - default unlimited (no decay)
promoted_keep=-1  # -1 means keep all, 0 means none, N means keep N most recent

usage() {
  cat <<'EOF'
autodream-memory.sh - memory compaction + promotion workflow

Usage:
  ./hacks/autodream-memory.sh [--session-id <id>] [options]

Modes:
  Default mode is report-only (no writes)
  Use --apply to run promotion and optional handoff writes

Options:
  --session-id <id>      Session ID to compact/promote (optional; inferred when omitted)
  --prefer-stale         Inference mode: prefer stale sessions first (default)
  --prefer-recent        Inference mode: prefer most recently updated session
  --stale-hours <hours>  Stale threshold for inference (default: 24)
  --scan-limit <n>       Max sessions to scan during inference/listing (default: 50)
  --list-sessions        Print session candidates and exit
  --batch                Process multiple sessions in bounded batches
  --batch-max-seconds <n>
                          Batch time budget in seconds (default: 170)
  --batch-max-sessions <n>
                          Max sessions per batch (default: 8)
  --batch-state-file <path>
                          Persist batch continuation state (default: ~/.agents/memory/autodream-batch-state.json)
  --batch-reset          Ignore and overwrite any previous batch state
  --batch-order <oldest|recent>
                          Session traversal order for batches (default: oldest)
  --no-result-lines      Suppress AUTODREAM_EVENT/AUTODREAM_RESULT output
  --project <slug>       Project slug for handoff generation (optional)
  --topic <topic>        Handoff topic when --project is set (default: autodream)
  --label <label>        Label suffix for promoted artifacts (default: autodream)
  --summary <text>       Override auto-generated handoff summary text
  --summarizer-cmd <cmd> Optional command to summarize compacted signal artifacts
  --db <path>            SQLite DB path (default: ~/.agents/memory/session.db)
  --agents-home <path>   Base directory for ~/.agents replacement
  --report-only          Print compaction report only (default)
  --apply                Run promote + optional handoff workflow
  --dry-run              Preview write actions without writing
  --promoted-keep <n>    Keep N most recent promoted sets (default: unlimited/no decay)
  -h, --help             Show this help text

Examples:
  ./hacks/autodream-memory.sh --session-id opencode-2026-03-25
  ./hacks/autodream-memory.sh
  ./hacks/autodream-memory.sh --prefer-recent
  ./hacks/autodream-memory.sh --list-sessions
  ./hacks/autodream-memory.sh --batch --batch-max-seconds 170
  ./hacks/autodream-memory.sh --batch --batch-reset --batch-order oldest
  ./hacks/autodream-memory.sh --session-id opencode-2026-03-25 --summarizer-cmd 'python3 ~/bin/summarize.py'
  ./hacks/autodream-memory.sh --session-id opencode-2026-03-25 --apply
  ./hacks/autodream-memory.sh --session-id opencode-2026-03-25 --project dotfiles --topic memory --apply
EOF
}

log() {
  printf '%s\n' "$*"
}

sanitize_value() {
  local value=${1:-}
  value=${value//$'\n'/ }
  value=${value//$'\r'/ }
  value=${value//$'\t'/ }
  printf '%s' "$value"
}

emit_kv_line() {
  local prefix=$1
  shift

  printf '%s' "$prefix"
  local field key value
  for field in "$@"; do
    key=${field%%=*}
    value=${field#*=}
    value=$(sanitize_value "$value")
    printf '\t%s=%s' "$key" "$value"
  done
  printf '\n'
}

emit_event() {
  if [[ "$suppress_result_lines" == "true" ]]; then
    return 0
  fi
  emit_kv_line "AUTODREAM_EVENT" "$@"
}

emit_result_once() {
  if [[ "$result_emitted" == "true" ]]; then
    return 0
  fi

  if [[ "$suppress_result_lines" == "true" ]]; then
    result_emitted=true
    return 0
  fi

  emit_kv_line "AUTODREAM_RESULT" "$@"
  result_emitted=true
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  emit_result_once \
    "status=failure" \
    "mode=$run_mode" \
    "session_id=${session_id:-unknown}" \
    "selection_reason=${session_selection_note:-unknown}" \
    "promoted_artifact=$promoted_artifact_state" \
    "project_scaffold=$project_scaffold_state" \
    "handoff_artifact=$handoff_artifact_state" \
    "artifacts_created=false" \
    "next_step=Inspect ERROR output and rerun with --list-sessions or --help"
  exit 1
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

resolve_db_path() {
  db_path_candidates=()

  add_candidate() {
    local candidate=${1:-}
    [[ -n "$candidate" ]] || return 0

    local existing
    for existing in "${db_path_candidates[@]:-}"; do
      if [[ "$existing" == "$candidate" ]]; then
        return 0
      fi
    done

    db_path_candidates+=("$candidate")
  }

  db_candidate_stats() {
    local candidate_db=$1
    python3 - "$candidate_db" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]

try:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    tables = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('session_contexts', 'interactions')"
        ).fetchall()
    }

    has_session_contexts = 1 if "session_contexts" in tables else 0
    has_interactions = 1 if "interactions" in tables else 0

    session_context_rows = 0
    interactions_rows = 0

    if has_session_contexts:
        session_context_rows = conn.execute("SELECT COUNT(*) FROM session_contexts").fetchone()[0]

    if has_interactions:
        interactions_rows = conn.execute("SELECT COUNT(*) FROM interactions").fetchone()[0]

    print(f"{has_session_contexts}\t{session_context_rows}\t{has_interactions}\t{interactions_rows}")
    conn.close()
except Exception:
    raise SystemExit(1)

raise SystemExit(0)
PY
  }

  local memory_dir="$agents_home/memory"
  local legacy_dir="$HOME/.opencode/sessions"
  local pattern
  local candidate

  if [[ "$db_path_explicit" == "true" ]]; then
    add_candidate "$db_path"
  else
    add_candidate "$db_path"
    add_candidate "$default_db_path"
    add_candidate "$memory_dir/session-repaired.db"
    add_candidate "$memory_dir/session.db.repaired"
    add_candidate "$legacy_db_path"
    add_candidate "$legacy_dir/session-repaired.db"

    shopt -s nullglob
    for pattern in \
      "$memory_dir"/session.db.backup.* \
      "$memory_dir"/session.db.bak.* \
      "$memory_dir"/session-*.db \
      "$legacy_dir"/session.db.backup.* \
      "$legacy_dir"/session.db.bak.* \
      "$legacy_dir"/session-*.db; do
      add_candidate "$pattern"
    done
    shopt -u nullglob
  fi

  local primary_candidate="${db_path_candidates[0]:-}"
  local checked=0
  local best_context_candidate=""
  local best_context_rows=-1
  local best_interactions_candidate=""
  local best_interactions_rows=-1
  local primary_has_any_schema="false"
  local primary_context_rows=0
  local primary_interactions_rows=0
  local stats_line
  local has_contexts context_rows has_interactions interactions_rows

  for candidate in "${db_path_candidates[@]:-}"; do
    [[ -f "$candidate" ]] || continue
    checked=$((checked + 1))

    if ! stats_line="$(db_candidate_stats "$candidate")"; then
      continue
    fi

    IFS=$'\t' read -r has_contexts context_rows has_interactions interactions_rows <<< "$stats_line"

    if [[ "$candidate" == "$primary_candidate" ]]; then
      if [[ "$has_contexts" == "1" || "$has_interactions" == "1" ]]; then
        primary_has_any_schema="true"
      fi
      primary_context_rows="${context_rows:-0}"
      primary_interactions_rows="${interactions_rows:-0}"
    fi

    if [[ "$has_contexts" == "1" ]]; then
      if (( context_rows > best_context_rows )); then
        best_context_rows=$context_rows
        best_context_candidate="$candidate"
      fi
    fi

    if [[ "$has_interactions" == "1" ]]; then
      if (( interactions_rows > best_interactions_rows )); then
        best_interactions_rows=$interactions_rows
        best_interactions_candidate="$candidate"
      fi
    fi
  done

  if [[ "$db_path_explicit" == "true" ]]; then
    if [[ -f "$db_path" ]]; then
      if [[ "$primary_has_any_schema" == "true" ]]; then
        db_selection_note="explicit-db-valid"
      else
        db_selection_note="explicit-db-invalid-or-missing-schema"
      fi
    else
      db_selection_note="explicit-db-invalid-or-missing-schema"
    fi
    return
  fi

  if [[ "$primary_has_any_schema" == "true" && "$primary_context_rows" -gt 0 ]]; then
    db_path="$primary_candidate"
    db_selection_note="primary-candidate-has-session-contexts"
    return
  fi

  if [[ -n "$best_context_candidate" && "$best_context_rows" -gt 0 ]]; then
    db_path="$best_context_candidate"
    if [[ "$best_context_candidate" == "$primary_candidate" ]]; then
      db_selection_note="primary-candidate-has-session-contexts"
    else
      db_selection_note="fallback-candidate-has-session-contexts"
    fi
    return
  fi

  if [[ -n "$best_interactions_candidate" && "$best_interactions_rows" -gt 0 ]]; then
    db_path="$best_interactions_candidate"
    if [[ "$best_interactions_candidate" == "$primary_candidate" ]]; then
      db_selection_note="primary-candidate-has-interactions"
    else
      db_selection_note="fallback-candidate-has-interactions"
    fi
    return
  fi

  if [[ "$primary_has_any_schema" == "true" ]]; then
    db_path="$primary_candidate"
    db_selection_note="primary-candidate-schema-only"
    return
  fi

  if [[ -n "$best_context_candidate" ]]; then
    db_path="$best_context_candidate"
    db_selection_note="fallback-candidate-schema-only"
    return
  fi

  if [[ -n "$best_interactions_candidate" ]]; then
    db_path="$best_interactions_candidate"
    db_selection_note="fallback-candidate-schema-only"
    return
  fi

  if [[ "$checked" -eq 0 ]]; then
    db_selection_note="no-candidate-files-found"
  else
    db_selection_note="no-candidates-with-runtime-session-data"
  fi

  if [[ -z "$primary_candidate" ]]; then
    db_path="$default_db_path"
  else
    db_path="$primary_candidate"
  fi
}

enforce_safe_apply_db() {
  if [[ "$apply_changes" != "true" || "$db_path_explicit" == "true" ]]; then
    return 0
  fi

  local canonical_candidate=""
  if [[ -f "$default_db_path" ]]; then
    canonical_candidate="$default_db_path"
  elif [[ -f "$legacy_db_path" ]]; then
    canonical_candidate="$legacy_db_path"
  fi

  [[ -n "$canonical_candidate" ]] || return 0

  if [[ "$db_path" != "$canonical_candidate" ]]; then
    warn "Apply mode forcing canonical DB path: $canonical_candidate (was: $db_path)"
    db_path="$canonical_candidate"
    db_selection_note="${db_selection_note};apply-canonical-override"
  fi
}

get_user_preference_count() {
  local target_db=$1
  python3 - "$target_db" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
try:
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='user_preferences'"
    ).fetchone()
    if not table:
        print("missing")
    else:
        count = conn.execute("SELECT COUNT(*) FROM user_preferences").fetchone()[0]
        print(str(count))
    conn.close()
except Exception:
    print("unknown")
PY
}

verify_preferences_unchanged() {
  if [[ "$apply_changes" != "true" || "$dry_run" == "true" ]]; then
    return 0
  fi

  if [[ -z "$pref_count_before" || "$pref_count_before" == "missing" || "$pref_count_before" == "unknown" ]]; then
    return 0
  fi

  local pref_count_after
  pref_count_after="$(get_user_preference_count "$db_path")"
  if [[ "$pref_count_after" != "$pref_count_before" ]]; then
    die "Safety check failed: user_preferences row count changed ($pref_count_before -> $pref_count_after)"
  fi
}

publish_project_autodream_artifact_note() {
  [[ -n "$project_slug" ]] || return 0
  [[ "$dry_run" != "true" ]] || return 0

  local promoted_dir="$agents_home/memory/promoted"
  local handoff_dir="$agents_home/memory/handoffs/$(date +%Y)/$(date +%m)"
  local project_artifacts_dir="$agents_home/memory/projects/$project_slug/artifacts"

  local latest_promoted_json=""
  local latest_promoted_md=""
  local latest_compacted_json=""
  local latest_compacted_md=""
  local latest_handoff_md=""
  local candidate

  shopt -s nullglob
  for candidate in "$promoted_dir"/*-"$session_id_slug"-"$label_slug".json; do
    latest_promoted_json="$candidate"
  done
  for candidate in "$promoted_dir"/*-"$session_id_slug"-"$label_slug".md; do
    latest_promoted_md="$candidate"
  done
  for candidate in "$promoted_dir"/*-"$session_id_slug"-"$label_slug"-compact.json; do
    latest_compacted_json="$candidate"
  done
  for candidate in "$promoted_dir"/*-"$session_id_slug"-"$label_slug"-compact.md; do
    latest_compacted_md="$candidate"
  done
  for candidate in "$handoff_dir"/*-"$project_slug"-"$topic_slug".md; do
    latest_handoff_md="$candidate"
  done
  shopt -u nullglob

  mkdir -p "$project_artifacts_dir"
  local note_path="$project_artifacts_dir/autodream-$session_id_slug-latest.md"

  umask 077
  {
    printf -- '---\n'
    printf -- 'artifact_type: project-artifact-index\n'
    printf -- 'project: %s\n' "$project_slug"
    printf -- 'session_id: %s\n' "$session_id"
    printf -- 'source: autodream-memory\n'
    printf -- 'updated_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf -- '---\n\n'
    printf '# Autodream Artifacts\n\n'
    printf -- '- Session ID: `%s`\n' "$session_id"
    printf -- '- Updated at: `%s`\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ -n "$latest_promoted_json" ]]; then
      printf -- '- Promoted JSON: `%s`\n' "$latest_promoted_json"
    fi
    if [[ -n "$latest_promoted_md" ]]; then
      printf -- '- Promoted Summary: `%s`\n' "$latest_promoted_md"
    fi
    if [[ -n "$latest_compacted_json" ]]; then
      printf -- '- Compacted Signal JSON: `%s`\n' "$latest_compacted_json"
    fi
    if [[ -n "$latest_compacted_md" ]]; then
      printf -- '- Compacted Signal Summary: `%s`\n' "$latest_compacted_md"
    fi
    if [[ -n "$latest_handoff_md" ]]; then
      printf -- '- Handoff: `%s`\n' "$latest_handoff_md"
    fi
    printf '\nUse /memory show --project %s --topic artifacts/%s\n' "$project_slug" "$(basename "$note_path")"
  } > "$note_path"

  log "Published autodream artifact note: $note_path"
}

write_compacted_signal_artifacts() {
  local compact_json_source=$1
  local compact_md_source=$2

  local promoted_dir="$agents_home/memory/promoted"
  local ts compact_base compact_json_path compact_md_path

  ts="$(date +%Y%m%d%H%M%S)"
  compact_base="$ts-$session_id_slug-$label_slug-compact"
  compact_json_path="$promoted_dir/$compact_base.json"
  compact_md_path="$promoted_dir/$compact_base.md"

  mkdir -p "$promoted_dir"

  if [[ "$dry_run" == "true" ]]; then
    log "DRY RUN: write compacted signal artifact $compact_json_path"
    log "DRY RUN: write compacted signal artifact $compact_md_path"
    return 0
  fi

  [[ -f "$compact_json_source" ]] || die "Missing compacted signal JSON source: $compact_json_source"
  [[ -f "$compact_md_source" ]] || die "Missing compacted signal markdown source: $compact_md_source"

  umask 077
  cp "$compact_json_source" "$compact_json_path"
  cp "$compact_md_source" "$compact_md_path"

  log "Wrote compacted signal artifacts:"
  log "- $compact_json_path"
  log "- $compact_md_path"
}

run_optional_summarizer() {
  [[ -n "$summarizer_cmd" ]] || return 0
  [[ -f "$compacted_signal_json_file" ]] || return 0
  [[ -f "$compacted_signal_md_file" ]] || return 0

  local project_slug_value="${project_slug:-}"
  local summary_output_dir="$agents_home/memory/projects/${project_slug_value:-general}/artifacts"
  local summary_output_file="$summary_output_dir/autodream-${session_id_slug}-${label_slug}-summary.md"

  if [[ "$dry_run" == "true" ]]; then
    log "DRY RUN: run summarizer command against compacted signal artifacts"
    log "DRY RUN: write summarizer output to $summary_output_file"
    return 0
  fi

  mkdir -p "$summary_output_dir"

  local tmp_output
  tmp_output=$(mktemp)

  if ! AUTODREAM_JSON_PATH="$compacted_signal_json_file" \
       AUTODREAM_MD_PATH="$compacted_signal_md_file" \
       AUTODREAM_OUTPUT_PATH="$tmp_output" \
       AUTODREAM_SESSION_ID="$session_id" \
       AUTODREAM_PROJECT="$project_slug_value" \
       AUTODREAM_TOPIC="$topic_slug" \
       bash -lc "$summarizer_cmd"; then
    rm -f "$tmp_output"
    log "WARN: summarizer command failed (non-fatal)"
    return 0
  fi

  if [[ ! -s "$tmp_output" ]]; then
    rm -f "$tmp_output"
    log "WARN: summarizer produced no output (non-fatal)"
    return 0
  fi

  {
    printf -- '---\n'
    printf -- 'artifact_type: autodream-summary\n'
    printf -- 'project: %s\n' "${project_slug_value:-general}"
    printf -- 'session_id: %s\n' "$session_id"
    printf -- 'topic: %s\n' "$topic_slug"
    printf -- 'source: autodream-summarizer\n'
    printf -- 'created_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf -- '---\n\n'
    cat "$tmp_output"
    printf '\n'
  } > "$summary_output_file"
  rm -f "$tmp_output"
  log "Wrote summarizer artifact: $summary_output_file"
}

populate_project_files_from_signal() {
  # Populates project scaffold files (current.md, decisions.md, MEMORY.md)
  # from the autodream compacted signal JSON.
  [[ -n "$project_slug" ]] || return 0
  [[ "$dry_run" != "true" ]] || return 0

  local project_dir="$agents_home/memory/projects/$project_slug"
  local compact_json="$compacted_signal_json_file"

  [[ -d "$project_dir" ]] || { log "WARN: project dir not found: $project_dir"; return 0; }
  [[ -f "$compact_json" ]] || { log "WARN: compacted signal JSON not found: $compact_json"; return 0; }

  log "Populating project files from autodream signal..."

  python3 - "$compact_json" "$project_dir" "$session_id" "$project_slug" <<'POPULATE_PY'
import json
import re
import sys
from datetime import datetime, timezone

compact_json_path, project_dir, session_id, project_slug = sys.argv[1:5]

with open(compact_json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

signal = data.get("signal", {})
scoring = data.get("scoring", {})
totals = data.get("totals", {})
generated_at = data.get("generated_at", datetime.now(timezone.utc).isoformat())

decisions = signal.get("decisions", [])
blockers = signal.get("blockers", [])
next_actions = signal.get("next_actions", [])
learnings = signal.get("learnings", [])
high_signal = signal.get("high_signal_candidates", [])

# --- Smart formatting helpers ---

def fmt_date(record):
    ts = record.get("updated_at", "")
    if "T" in ts:
        return ts[:10]
    elif " " in ts:
        return ts.split(" ")[0]
    return ts or "unknown"

def fmt_value(record, max_len=200):
    val = record.get("value", "").strip().replace("\n", " ")
    return val[:max_len] + "..." if len(val) > max_len else val

def parse_task_title(record, max_len=150):
    """Extract clean title from task-tracker format: 'title=... | state=...' """
    val = record.get("value", "").strip()
    # Match task-tracker pipe-delimited format
    m = re.match(r"title=(.+?)(?:\s*\|\s*(?:state|priority|phase|progress|description)=)", val)
    if m:
        title = m.group(1).strip().rstrip(".")
        return title[:max_len] + "..." if len(title) > max_len else title
    # Fallback: numbered list items ("1. Do X. 2. Do Y.")
    if re.match(r"^\d+\.\s", val):
        items = re.split(r"\s*\d+\.\s+", val)
        items = [i.strip().rstrip(".") for i in items if i.strip()]
        if items:
            return items[0][:max_len] + ("..." if len(items[0]) > max_len else "")
    return fmt_value(record, max_len)

def parse_decision(record, max_len=200):
    """Clean up decision values: strip markdown headers, extract core content."""
    val = record.get("value", "").strip()
    # If it looks like a task-tracker record, extract title
    if re.match(r"title=", val):
        return parse_task_title(record, max_len)
    # Remove markdown headers (### Title\n...)
    val = re.sub(r"^#{1,4}\s+", "", val)
    # Collapse multi-line to single line
    val = re.sub(r"\s*\n\s*", " ", val)
    # Remove nested headers mid-string
    val = re.sub(r"\s*#{1,4}\s+", " — ", val)
    val = val.strip()
    return val[:max_len] + "..." if len(val) > max_len else val

def parse_identity(val):
    """Parse 'key: value key2: value2 ...' identity string into structured dict."""
    # Known identity keys in expected order
    known_keys = [
        "preferred_name", "user_name", "zip_code", "role",
        "domains", "environment", "communication_style",
        "decision_style", "work_hours", "timezone",
    ]
    result = {}
    # Try to split on known key boundaries
    pattern = r"(" + "|".join(known_keys) + r"):\s*"
    parts = re.split(pattern, val)
    # parts = [preamble, key1, val1, key2, val2, ...]
    if len(parts) >= 3:
        for i in range(1, len(parts) - 1, 2):
            k = parts[i].strip()
            v = parts[i + 1].strip().rstrip(".").strip()
            # Remove trailing key names that got included
            for nk in known_keys:
                if v.endswith(f" {nk}"):
                    v = v[: -(len(nk) + 1)].strip()
            if v and v != "...":
                result[k] = v
    return result

IDENTITY_LABELS = {
    "preferred_name": "Name",
    "user_name": "Full Name",
    "role": "Role",
    "domains": "Domains",
    "environment": "Environment",
    "zip_code": "Location (ZIP)",
    "communication_style": "Communication",
    "decision_style": "Decision Style",
    "work_hours": "Work Hours",
    "timezone": "Timezone",
}

# --- current.md ---
current_lines = [
    "---",
    "artifact_type: project-current",
    f"project: {project_slug}",
    f"session_id: {session_id}",
    f"updated_at: {generated_at}",
    "source: autodream-memory",
    "---",
    "",
    "# Current State",
    "",
    f"_Auto-populated by autodream (semantic-v2) at {generated_at}_",
    "",
    "## Status",
    f"- Autodream analyzed {totals.get('rows', '?')} session records for `{session_id}`",
    f"- Scoring: mean={scoring.get('mean_score', '?')}, max={scoring.get('max_score', '?')}",
    "",
    "## Blockers",
]
if blockers:
    for item in blockers:
        current_lines.append(f"- {parse_task_title(item)}")
else:
    current_lines.append("- No active blockers detected")

current_lines.extend(["", "## Next Actions"])
if next_actions:
    for i, item in enumerate(next_actions[:8], 1):
        current_lines.append(f"{i}. {parse_task_title(item)}")
else:
    current_lines.append("1. Run `/autodream --apply` with active session data")

current_path = f"{project_dir}/current.md"
with open(current_path, "w", encoding="utf-8") as f:
    f.write("\n".join(current_lines) + "\n")

# --- decisions.md ---
decisions_lines = [
    "---",
    "artifact_type: project-decisions",
    f"project: {project_slug}",
    f"session_id: {session_id}",
    f"updated_at: {generated_at}",
    "source: autodream-memory",
    "---",
    "",
    "# Decisions",
    "",
    f"_Auto-populated by autodream (semantic-v2) at {generated_at}_",
    "",
]
if decisions:
    for item in decisions:
        date = fmt_date(item)
        key = item.get("key", "")
        val = parse_decision(item, 250)
        decisions_lines.append(f"- {date}: [{key}] {val}")
else:
    decisions_lines.append("- No decision records extracted from session data")

if learnings:
    decisions_lines.extend(["", "## Learnings", ""])
    for item in learnings:
        date = fmt_date(item)
        key = item.get("key", "")
        # Skip identity records in learnings section
        if "identity" in key:
            continue
        val = fmt_value(item, 250)
        decisions_lines.append(f"- {date}: [{key}] {val}")

decisions_path = f"{project_dir}/decisions.md"
with open(decisions_path, "w", encoding="utf-8") as f:
    f.write("\n".join(decisions_lines) + "\n")

# --- MEMORY.md (Claude Code compatible) ---
memory_lines = [
    "---",
    "artifact_type: project-memory",
    f"project: {project_slug}",
    f"session_id: {session_id}",
    f"updated_at: {generated_at}",
    "source: autodream-memory",
    "---",
    "",
    f"# {project_slug} Project Memory",
    "",
    f"_Last updated by autodream (semantic-v2) at {generated_at}_",
    "",
    "## User Identity",
    "",
]

# Extract and parse identity from learnings/high-signal
identity_found = False
for item in learnings + high_signal:
    key = item.get("key", "")
    if "identity" in key:
        raw_val = item.get("value", "").strip()
        parsed = parse_identity(raw_val)
        if parsed:
            for k, v in parsed.items():
                label = IDENTITY_LABELS.get(k, k.replace("_", " ").title())
                memory_lines.append(f"- **{label}**: {v}")
            identity_found = True
        break
if not identity_found:
    memory_lines.append(f"- Session: `{session_id}`")

memory_lines.extend(["", "## Active Decisions", ""])
if decisions:
    for item in decisions:
        val = parse_decision(item, 200)
        memory_lines.append(f"- {val}")
else:
    memory_lines.append("- None extracted")

memory_lines.extend(["", "## Current Blockers", ""])
if blockers:
    for item in blockers:
        val = parse_task_title(item, 200)
        memory_lines.append(f"- {val}")
else:
    memory_lines.append("- None")

memory_lines.extend(["", "## Next Actions", ""])
if next_actions:
    for i, item in enumerate(next_actions[:8], 1):
        val = parse_task_title(item, 200)
        memory_lines.append(f"{i}. {val}")
else:
    memory_lines.append("1. Populate with active tasks")

memory_lines.extend(["", "## Learnings & Conventions", ""])
learning_items = [l for l in learnings if "identity" not in l.get("key", "")]
if learning_items:
    for item in learning_items:
        val = fmt_value(item, 200)
        memory_lines.append(f"- {val}")
else:
    memory_lines.append("- None extracted")

memory_lines.extend([
    "",
    "## Scoring Metadata",
    "",
    f"- Algorithm: {scoring.get('algorithm', 'unknown')}",
    f"- Records analyzed: {totals.get('rows', '?')}",
    f"- High-signal count: {scoring.get('high_signal_count', '?')}",
    f"- Score range: {scoring.get('min_score', '?')} - {scoring.get('max_score', '?')} (mean: {scoring.get('mean_score', '?')})",
    f"- Bucket counts: {', '.join(f'{k}={v}' for k, v in scoring.get('bucket_counts', {}).items())}",
    "",
])

memory_path = f"{project_dir}/MEMORY.md"
with open(memory_path, "w", encoding="utf-8") as f:
    f.write("\n".join(memory_lines) + "\n")

print(f"Populated: {current_path}")
print(f"Populated: {decisions_path}")
print(f"Created:   {memory_path}")
POPULATE_PY

  if [[ $? -ne 0 ]]; then
    log "WARN: Failed to populate project files from signal (non-fatal)"
    return 0
  fi
}

record_autodream_metrics() {
  # Writes a row to autodream_runs in the session DB using compact signal JSON.
  # Args: $1=duration_ms (optional, 0 if unknown)
  local duration_ms="${1:-0}"
  local compact_json="$compacted_signal_json_file"

  [[ -f "$compact_json" ]] || { log "WARN: no compact JSON for metrics"; return 0; }
  [[ -f "$db_path" ]] || { log "WARN: no DB for metrics"; return 0; }

  python3 - "$compact_json" "$db_path" "$session_id" "$project_slug" "$topic_slug" "$run_mode" "$duration_ms" <<'METRICS_PY'
import json, sqlite3, sys

compact_path, db_path, session_id, project, topic, mode, duration_ms_str = sys.argv[1:8]
duration_ms = int(duration_ms_str) if duration_ms_str.isdigit() else 0

with open(compact_path, "r", encoding="utf-8") as f:
    data = json.load(f)

scoring = data.get("scoring", {})
totals = data.get("totals", {})
buckets = scoring.get("bucket_counts", {})

# Ensure the table exists (idempotent)
conn = sqlite3.connect(db_path)
conn.execute("""
    CREATE TABLE IF NOT EXISTS autodream_runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT NOT NULL,
      project TEXT,
      topic TEXT,
      mode TEXT NOT NULL DEFAULT 'report',
      schema_version INTEGER NOT NULL DEFAULT 2,
      total_rows_analyzed INTEGER,
      high_signal_count INTEGER,
      mean_score REAL,
      max_score REAL,
      bucket_decisions INTEGER DEFAULT 0,
      bucket_blockers INTEGER DEFAULT 0,
      bucket_next_actions INTEGER DEFAULT 0,
      bucket_learnings INTEGER DEFAULT 0,
      artifacts_created INTEGER DEFAULT 0,
      duration_ms INTEGER,
      created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
    )
""")
conn.execute("""
    CREATE INDEX IF NOT EXISTS idx_autodream_runs_session
    ON autodream_runs(session_id, created_at)
""")
conn.execute("""
    CREATE INDEX IF NOT EXISTS idx_autodream_runs_project
    ON autodream_runs(project, created_at)
""")

artifacts = 1 if mode == "apply" else 0

conn.execute("""
    INSERT INTO autodream_runs
      (session_id, project, topic, mode, schema_version,
       total_rows_analyzed, high_signal_count, mean_score, max_score,
       bucket_decisions, bucket_blockers, bucket_next_actions, bucket_learnings,
       artifacts_created, duration_ms)
    VALUES (?, ?, ?, ?, 2, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (
    session_id,
    project or None,
    topic or None,
    mode,
    totals.get("rows"),
    scoring.get("high_signal_count"),
    scoring.get("mean_score"),
    scoring.get("max_score"),
    buckets.get("decisions", 0),
    buckets.get("blockers", 0),
    buckets.get("next_actions", 0),
    buckets.get("learnings", 0),
    artifacts,
    duration_ms if duration_ms > 0 else None,
))
conn.commit()
conn.close()
print(f"Recorded autodream metrics: session={session_id} mode={mode}")
METRICS_PY

  if [[ $? -ne 0 ]]; then
    log "WARN: Failed to record autodream metrics (non-fatal)"
  else
    log "Autodream metrics recorded to DB."
  fi
}

prune_promoted_artifacts() {
  # Keeps only the most recent N artifact sets in ~/.agents/memory/promoted/.
  # An artifact set = 4 files sharing a timestamp prefix (full+compact × json+md).
  # Default retention: unlimited (no decay, when promoted_keep=-1).
  local promoted_dir="$agents_home/memory/promoted"
  local keep="${1:--1}"

  # No pruning when keep=-1 (unlimited)
  [[ "$keep" -eq -1 ]] && return 0

  [[ -d "$promoted_dir" ]] || return 0

  # List unique timestamp prefixes (format: YYYYMMDDHHMMSS), sorted descending
  local prefixes
  prefixes=$( (ls "$promoted_dir" 2>/dev/null | grep -oE '^[0-9]{14}' | sort -ru) || true )
  local count
  count=$(printf '%s\n' "$prefixes" | grep -c . || true)

  if [[ "$count" -le "$keep" ]]; then
    log "Promoted retention: $count sets, keeping all (limit=$keep)"
    return 0
  fi

  local to_delete
  to_delete=$(printf '%s\n' "$prefixes" | tail -n +"$((keep + 1))")
  local deleted=0
  while IFS= read -r prefix; do
    [[ -n "$prefix" ]] || continue
    for f in "$promoted_dir"/"${prefix}"-*; do
      [[ -f "$f" ]] || continue
      if [[ "$dry_run" == "true" ]]; then
        log "  [dry-run] would remove: $(basename "$f")"
      else
        rm -f "$f"
        deleted=$((deleted + 1))
      fi
    done
  done <<< "$to_delete"

  log "Promoted retention: pruned $deleted files, kept $keep most recent sets"
}

list_session_candidates_report() {
  python3 - "$db_path" "$scan_limit" <<'PY'
import sqlite3
import sys
from datetime import datetime, timezone

db_path, scan_limit_raw = sys.argv[1:3]
scan_limit = max(1, int(scan_limit_raw))

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

tables = {
    row[0]
    for row in conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type='table'
          AND name IN ('session_contexts', 'interactions', 'tasks', 'work_sessions')
        """
    ).fetchall()
}

session_index = {}

def parse_ts(raw):
    if not raw:
        return None
    for candidate in (raw, raw.replace("Z", "+00:00")):
        try:
            dt = datetime.fromisoformat(candidate)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.timestamp()
        except ValueError:
            continue
    try:
        dt = datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        return dt.timestamp()
    except ValueError:
        return None

def upsert(source, session_id, row_count, latest_update):
    sid = (session_id or "").strip()
    if not sid:
        return
    current = session_index.setdefault(
        sid,
        {
            "session_id": sid,
            "row_count": 0,
            "latest_update": None,
            "latest_ts": None,
            "sources": [],
            "source_counts": {},
        },
    )
    current["row_count"] += int(row_count or 0)
    current["source_counts"][source] = int(row_count or 0)
    if source not in current["sources"]:
        current["sources"].append(source)

    ts = parse_ts(latest_update)
    if ts and (current["latest_ts"] is None or ts > current["latest_ts"]):
        current["latest_ts"] = ts
        current["latest_update"] = latest_update
    elif current["latest_update"] is None and latest_update:
        current["latest_update"] = latest_update

if "session_contexts" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(updated_at) AS latest_update
        FROM session_contexts
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("session_contexts", row["session_id"], row["row_count"], row["latest_update"])

if "interactions" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM interactions
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("interactions", row["session_id"], row["row_count"], row["latest_update"])

if "tasks" in tables:
    rows = conn.execute(
        """
        SELECT workflow_id AS session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM tasks
        WHERE workflow_id IS NOT NULL AND TRIM(workflow_id) != ''
        GROUP BY workflow_id
        """
    ).fetchall()
    for row in rows:
        upsert("tasks", row["session_id"], row["row_count"], row["latest_update"])

if "work_sessions" in tables:
    rows = conn.execute(
        """
        SELECT
          session_key AS session_id,
          COUNT(*) AS row_count,
          MAX(COALESCE(ended_at, updated_at, created_at, started_at)) AS latest_update
        FROM work_sessions
        WHERE session_key IS NOT NULL AND TRIM(session_key) != ''
        GROUP BY session_key
        """
    ).fetchall()
    for row in rows:
        upsert("work_sessions", row["session_id"], row["row_count"], row["latest_update"])

conn.close()

rows = sorted(
    session_index.values(),
    key=lambda item: item["latest_ts"] or 0,
    reverse=True,
)[:scan_limit]

if not rows:
    print("No session candidates found in session_contexts/interactions/tasks/work_sessions.")
    raise SystemExit(0)

print("Session candidates (latest first, aggregated sources=session_contexts,interactions,tasks,work_sessions):")

for row in rows:
    session_id = row["session_id"] or "(unknown)"
    row_count = row["row_count"]
    latest_update = row["latest_update"] or "unknown"
    latest_ts = row["latest_ts"]
    age_hours = None
    if latest_ts is not None:
        age_hours = round((datetime.now(timezone.utc).timestamp() - latest_ts) / 3600.0, 1)
    age_label = "unknown"
    if age_hours is not None:
        age_label = f"{age_hours}h"
    source_breakdown = ",".join(
        f"{name}:{count}" for name, count in sorted(row["source_counts"].items())
    )
    print(
        f"- {session_id} | rows={row_count} | latest={latest_update} | age={age_label} | sources={source_breakdown}"
    )
PY
}

infer_session_id() {
  python3 - "$db_path" "$session_pick_mode" "$stale_hours" "$scan_limit" <<'PY'
import sqlite3
import sys
from datetime import datetime, timezone

db_path, mode, stale_hours_raw, scan_limit_raw = sys.argv[1:5]
stale_hours = float(stale_hours_raw)
scan_limit = max(1, int(scan_limit_raw))

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

tables = {
    row[0]
    for row in conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type='table'
          AND name IN ('session_contexts', 'interactions', 'tasks', 'work_sessions')
        """
    ).fetchall()
}

session_index = {}

def parse_ts(raw):
    if not raw:
        return None
    for candidate in (raw, raw.replace("Z", "+00:00")):
        try:
            dt = datetime.fromisoformat(candidate)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.timestamp()
        except ValueError:
            continue
    try:
        dt = datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        return dt.timestamp()
    except ValueError:
        return None

def score(entry):
    source_bonus = {
        "session_contexts": 60,
        "interactions": 35,
        "tasks": 25,
        "work_sessions": 15,
    }
    source_score = sum(source_bonus.get(name, 0) for name in entry["source_counts"])
    diversity_score = len(entry["source_counts"]) * 10
    return entry["row_count"] + source_score + diversity_score

def upsert(source, session_id, row_count, latest_update):
    sid = (session_id or "").strip()
    if not sid:
        return
    current = session_index.setdefault(
        sid,
        {
            "session_id": sid,
            "row_count": 0,
            "latest_update": None,
            "latest_ts": None,
            "age_hours": None,
            "source_counts": {},
        },
    )
    current["row_count"] += int(row_count or 0)
    current["source_counts"][source] = int(row_count or 0)

    ts = parse_ts(latest_update)
    if ts and (current["latest_ts"] is None or ts > current["latest_ts"]):
        current["latest_ts"] = ts
        current["latest_update"] = latest_update
    elif current["latest_update"] is None and latest_update:
        current["latest_update"] = latest_update

if "session_contexts" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(updated_at) AS latest_update
        FROM session_contexts
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("session_contexts", row["session_id"], row["row_count"], row["latest_update"])

if "interactions" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM interactions
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("interactions", row["session_id"], row["row_count"], row["latest_update"])

if "tasks" in tables:
    rows = conn.execute(
        """
        SELECT workflow_id AS session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM tasks
        WHERE workflow_id IS NOT NULL AND TRIM(workflow_id) != ''
        GROUP BY workflow_id
        """
    ).fetchall()
    for row in rows:
        upsert("tasks", row["session_id"], row["row_count"], row["latest_update"])

if "work_sessions" in tables:
    rows = conn.execute(
        """
        SELECT
          session_key AS session_id,
          COUNT(*) AS row_count,
          MAX(COALESCE(ended_at, updated_at, created_at, started_at)) AS latest_update
        FROM work_sessions
        WHERE session_key IS NOT NULL AND TRIM(session_key) != ''
        GROUP BY session_key
        """
    ).fetchall()
    for row in rows:
        upsert("work_sessions", row["session_id"], row["row_count"], row["latest_update"])

conn.close()

rows = list(session_index.values())
for row in rows:
    latest_ts = row["latest_ts"]
    if latest_ts is not None:
        row["age_hours"] = round((datetime.now(timezone.utc).timestamp() - latest_ts) / 3600.0, 1)
    row["score"] = score(row)

rows.sort(
    key=lambda item: (
        item["score"],
        item["latest_ts"] or 0,
    ),
    reverse=True,
)

rows = rows[:scan_limit]

if not rows:
    print("\tno sessions found in session_contexts/interactions/tasks/work_sessions\tunknown\tunknown\tunknown")
    raise SystemExit(0)

selected = None
reason = ""

if mode == "recent":
    selected = rows[0]
    reason = "best-scored recent session from aggregated sources"
else:
    for row in rows:
        age = row["age_hours"]
        if age is not None and age >= stale_hours:
            selected = row
            reason = f"stale-first selection (>= {stale_hours:g}h old) from aggregated sources"
            break
    if selected is None:
        selected = rows[0]
        reason = "stale-first fallback to best-scored recent session"

sources_label = ",".join(
    f"{name}:{count}" for name, count in sorted(selected["source_counts"].items())
)
reason = f"{reason}; sources={sources_label}"
age_value = selected.get("age_hours")
print(
    "\t".join(
        [
            selected["session_id"] or "",
            reason,
            str(selected["row_count"]),
            selected.get("latest_update") or "unknown",
            "unknown" if age_value is None else str(age_value),
        ]
    )
)
PY
}

build_batch_session_queue() {
  python3 - "$db_path" "$batch_order" <<'PY'
import sqlite3
import sys
from datetime import datetime, timezone

db_path, batch_order = sys.argv[1:3]

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

tables = {
    row[0]
    for row in conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type='table'
          AND name IN ('session_contexts', 'interactions', 'tasks', 'work_sessions')
        """
    ).fetchall()
}

session_index = {}

def parse_ts(raw):
    if not raw:
        return None
    for candidate in (raw, raw.replace("Z", "+00:00")):
        try:
            dt = datetime.fromisoformat(candidate)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.timestamp()
        except ValueError:
            continue
    try:
        dt = datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        return dt.timestamp()
    except ValueError:
        return None

def upsert(source, session_id, row_count, latest_update):
    sid = (session_id or "").strip()
    if not sid:
        return
    current = session_index.setdefault(
        sid,
        {
            "session_id": sid,
            "row_count": 0,
            "latest_update": None,
            "latest_ts": None,
            "source_counts": {},
        },
    )
    current["row_count"] += int(row_count or 0)
    current["source_counts"][source] = int(row_count or 0)

    ts = parse_ts(latest_update)
    if ts and (current["latest_ts"] is None or ts > current["latest_ts"]):
        current["latest_ts"] = ts
        current["latest_update"] = latest_update
    elif current["latest_update"] is None and latest_update:
        current["latest_update"] = latest_update

if "session_contexts" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(updated_at) AS latest_update
        FROM session_contexts
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("session_contexts", row["session_id"], row["row_count"], row["latest_update"])

if "interactions" in tables:
    rows = conn.execute(
        """
        SELECT session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM interactions
        GROUP BY session_id
        """
    ).fetchall()
    for row in rows:
        upsert("interactions", row["session_id"], row["row_count"], row["latest_update"])

if "tasks" in tables:
    rows = conn.execute(
        """
        SELECT workflow_id AS session_id, COUNT(*) AS row_count, MAX(created_at) AS latest_update
        FROM tasks
        WHERE workflow_id IS NOT NULL AND TRIM(workflow_id) != ''
        GROUP BY workflow_id
        """
    ).fetchall()
    for row in rows:
        upsert("tasks", row["session_id"], row["row_count"], row["latest_update"])

if "work_sessions" in tables:
    rows = conn.execute(
        """
        SELECT
          session_key AS session_id,
          COUNT(*) AS row_count,
          MAX(COALESCE(ended_at, updated_at, created_at, started_at)) AS latest_update
        FROM work_sessions
        WHERE session_key IS NOT NULL AND TRIM(session_key) != ''
        GROUP BY session_key
        """
    ).fetchall()
    for row in rows:
        upsert("work_sessions", row["session_id"], row["row_count"], row["latest_update"])

conn.close()

rows = list(session_index.values())
if batch_order == "recent":
    rows.sort(key=lambda item: item["latest_ts"] or 0, reverse=True)
else:
    rows.sort(key=lambda item: item["latest_ts"] or 0)

for row in rows:
    latest = row.get("latest_update") or "unknown"
    sources = ",".join(f"{name}:{count}" for name, count in sorted(row["source_counts"].items()))
    print("\t".join([row["session_id"], str(row["row_count"]), latest, sources]))
PY
}

load_batch_state() {
  python3 - "$batch_state_file" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
if not state_path.is_file():
    raise SystemExit(0)

try:
    payload = json.loads(state_path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

if not isinstance(payload, dict):
    raise SystemExit(0)

next_index = payload.get("next_index", 0)
ordered = payload.get("ordered_session_ids", [])
db_ref = payload.get("db_path", "")
order = payload.get("batch_order", "")

print(f"next_index\t{int(next_index) if isinstance(next_index, int) or str(next_index).isdigit() else 0}")
print(f"db_path\t{db_ref}")
print(f"batch_order\t{order}")
for sid in ordered:
    if isinstance(sid, str) and sid.strip():
        print(f"session\t{sid.strip()}")
PY
}

save_batch_state() {
  local next_index=$1
  shift
  python3 - "$batch_state_file" "$next_index" "$db_path" "$batch_order" "$@" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

state_file = Path(sys.argv[1])
next_index = int(sys.argv[2])
db_path = sys.argv[3]
batch_order = sys.argv[4]
ordered = sys.argv[5:]

payload = {
    "schema_version": 1,
    "updated_at": datetime.now(timezone.utc).isoformat(),
    "db_path": db_path,
    "batch_order": batch_order,
    "next_index": next_index,
    "ordered_session_ids": ordered,
}

state_file.parent.mkdir(parents=True, exist_ok=True)
state_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
}

run_single_session_subprocess() {
  local target_session_id=$1
  local script_path=${BASH_SOURCE[0]}

  local cmd=("$script_path" "--session-id" "$target_session_id" "--db" "$db_path" "--agents-home" "$agents_home" "--no-result-lines")

  if [[ "$apply_changes" == "true" ]]; then
    cmd+=("--apply")
  else
    cmd+=("--report-only")
  fi

  if [[ "$dry_run" == "true" ]]; then
    cmd+=("--dry-run")
  fi

  if [[ -n "$project" ]]; then
    cmd+=("--project" "$project")
  fi

  if [[ -n "$topic" ]]; then
    cmd+=("--topic" "$topic")
  fi

  if [[ -n "$label" ]]; then
    cmd+=("--label" "$label")
  fi

  if [[ -n "$summary_override" ]]; then
    cmd+=("--summary" "$summary_override")
  fi

  "${cmd[@]}"
}

run_batch_mode() {
  local now_epoch
  now_epoch=$(date +%s)
  local deadline=$((now_epoch + batch_max_seconds))

  if [[ -z "$batch_state_file" ]]; then
    batch_state_file="$agents_home/memory/autodream-batch-state.json"
  fi

  local queue_output
  if ! queue_output="$(build_batch_session_queue)"; then
    die "Failed to build batch session queue"
  fi

  local -a fresh_queue=()
  if [[ -n "$queue_output" ]]; then
    while IFS=$'\t' read -r sid _row_count _latest _sources; do
      [[ -n "${sid:-}" ]] || continue
      fresh_queue+=("$sid")
    done <<< "$queue_output"
  fi

  if [[ ${#fresh_queue[@]} -eq 0 ]]; then
    log "No session candidates available for batch processing."
    emit_result_once \
      "status=success" \
      "mode=$run_mode" \
      "session_id=none" \
      "selection_reason=batch-empty" \
      "promoted_artifact=$promoted_artifact_state" \
      "project_scaffold=$project_scaffold_state" \
      "handoff_artifact=$handoff_artifact_state" \
      "artifacts_created=false" \
      "next_step=No sessions found; capture context then rerun --batch"
    exit 0
  fi

  local -a queue=()
  local next_index=0

  if [[ "$batch_reset" != "true" && -f "$batch_state_file" ]]; then
    local state_line
    local state_db=""
    local state_order=""
    local state_next="0"
    local -a state_sessions=()

    while IFS=$'\t' read -r key value; do
      case "$key" in
        next_index) state_next="$value" ;;
        db_path) state_db="$value" ;;
        batch_order) state_order="$value" ;;
        session) state_sessions+=("$value") ;;
      esac
    done < <(load_batch_state)

    if [[ "$state_db" == "$db_path" && "$state_order" == "$batch_order" && ${#state_sessions[@]} -gt 0 ]]; then
      queue=("${state_sessions[@]}")
      next_index=$state_next
      log "Resuming batch state: next_index=$next_index total=${#queue[@]}"
    fi
  fi

  if [[ ${#queue[@]} -eq 0 ]]; then
    queue=("${fresh_queue[@]}")
    next_index=0
    log "Starting new batch traversal: total sessions=${#queue[@]} order=$batch_order"
  fi

  if [[ "$next_index" =~ ^[0-9]+$ ]]; then
    :
  else
    next_index=0
  fi

  if (( next_index >= ${#queue[@]} )); then
    log "All queued sessions already processed. Rebuilding queue for next cycle."
    queue=("${fresh_queue[@]}")
    next_index=0
  fi

  local processed_this_batch=0
  local failed_this_batch=0
  local -a processed_ids=()

  while (( next_index < ${#queue[@]} )); do
    if (( processed_this_batch >= batch_max_sessions )); then
      break
    fi

    local current_epoch
    current_epoch=$(date +%s)
    if (( current_epoch >= deadline )); then
      break
    fi

    local target_session="${queue[$next_index]}"
    log ""
    log "=== autodream batch: session $((next_index + 1))/${#queue[@]} -> $target_session ==="

    if run_single_session_subprocess "$target_session"; then
      processed_ids+=("$target_session")
      processed_this_batch=$((processed_this_batch + 1))
      next_index=$((next_index + 1))
    else
      warn "Batch session failed: $target_session"
      failed_this_batch=$((failed_this_batch + 1))
      next_index=$((next_index + 1))
    fi
  done

  save_batch_state "$next_index" "${queue[@]}"

  local remaining=$(( ${#queue[@]} - next_index ))
  if (( remaining < 0 )); then
    remaining=0
  fi

  log ""
  log "Batch summary: processed=$processed_this_batch failed=$failed_this_batch remaining=$remaining state=$batch_state_file"

  local next_step_msg
  if (( remaining > 0 )); then
    next_step_msg="Run again to continue next batch: ./hacks/autodream-memory.sh --batch"
  else
    next_step_msg="Batch traversal complete for current queue"
  fi

  emit_result_once \
    "status=success" \
    "mode=$run_mode" \
    "session_id=batch" \
    "selection_reason=batch-order-$batch_order" \
    "promoted_artifact=$promoted_artifact_state" \
    "project_scaffold=$project_scaffold_state" \
    "handoff_artifact=$handoff_artifact_state" \
    "artifacts_created=$([[ "$apply_changes" == "true" && "$dry_run" != "true" && "$processed_this_batch" -gt 0 ]] && printf 'true' || printf 'false')" \
    "next_step=$next_step_msg"

  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)
      [[ $# -ge 2 ]] || die "Missing value for --session-id"
      session_id="$2"
      shift 2
      ;;
    --prefer-stale)
      session_pick_mode="stale"
      shift
      ;;
    --prefer-recent)
      session_pick_mode="recent"
      shift
      ;;
    --stale-hours)
      [[ $# -ge 2 ]] || die "Missing value for --stale-hours"
      stale_hours="$2"
      shift 2
      ;;
    --scan-limit)
      [[ $# -ge 2 ]] || die "Missing value for --scan-limit"
      scan_limit="$2"
      shift 2
      ;;
    --list-sessions)
      list_session_candidates=true
      shift
      ;;
    --batch)
      single_session_mode=false
      shift
      ;;
    --batch-max-seconds)
      [[ $# -ge 2 ]] || die "Missing value for --batch-max-seconds"
      batch_max_seconds="$2"
      shift 2
      ;;
    --batch-max-sessions)
      [[ $# -ge 2 ]] || die "Missing value for --batch-max-sessions"
      batch_max_sessions="$2"
      shift 2
      ;;
    --batch-state-file)
      [[ $# -ge 2 ]] || die "Missing value for --batch-state-file"
      batch_state_file="$2"
      shift 2
      ;;
    --batch-reset)
      batch_reset=true
      shift
      ;;
    --batch-order)
      [[ $# -ge 2 ]] || die "Missing value for --batch-order"
      batch_order="$2"
      shift 2
      ;;
    --no-result-lines)
      suppress_result_lines=true
      shift
      ;;
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
    --label)
      [[ $# -ge 2 ]] || die "Missing value for --label"
      label="$2"
      shift 2
      ;;
    --summary)
      [[ $# -ge 2 ]] || die "Missing value for --summary"
      summary_override="$2"
      shift 2
      ;;
    --summarizer-cmd)
      [[ $# -ge 2 ]] || die "Missing value for --summarizer-cmd"
      summarizer_cmd="$2"
      shift 2
      ;;
    --db)
      [[ $# -ge 2 ]] || die "Missing value for --db"
      db_path="$2"
      db_path_explicit=true
      shift 2
      ;;
    --agents-home)
      [[ $# -ge 2 ]] || die "Missing value for --agents-home"
      agents_home="$2"
      agents_home_explicit=true
      default_db_path="$agents_home/memory/session.db"
      shift 2
      ;;
    --report-only)
      apply_changes=false
      shift
      ;;
    --apply)
      apply_changes=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --promoted-keep)
      [[ $# -ge 2 ]] || die "Missing value for --promoted-keep"
      promoted_keep="$2"
      shift 2
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

[[ "$stale_hours" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--stale-hours must be a non-negative number"
[[ "$scan_limit" =~ ^[0-9]+$ ]] || die "--scan-limit must be a positive integer"
(( scan_limit > 0 )) || die "--scan-limit must be greater than zero"
[[ "$batch_max_seconds" =~ ^[0-9]+$ ]] || die "--batch-max-seconds must be a positive integer"
(( batch_max_seconds > 0 )) || die "--batch-max-seconds must be greater than zero"
[[ "$batch_max_sessions" =~ ^[0-9]+$ ]] || die "--batch-max-sessions must be a positive integer"
(( batch_max_sessions > 0 )) || die "--batch-max-sessions must be greater than zero"
[[ "$batch_order" == "oldest" || "$batch_order" == "recent" ]] || die "--batch-order must be oldest or recent"
[[ "$promoted_keep" =~ ^-?[0-9]+$ ]] || die "--promoted-keep must be an integer (-1 for unlimited)"

if [[ -n "$session_id" ]]; then
  single_session_mode=true
fi

if [[ "$apply_changes" == "true" && "$dry_run" == "true" ]]; then
  run_mode="apply-dry-run"
elif [[ "$apply_changes" == "true" ]]; then
  run_mode="apply"
else
  run_mode="report-only"
fi

project_slug=""
if [[ -n "$project" ]]; then
  project_slug="$(slugify "$project")"
fi
topic_slug="$(slugify "$topic")"
label_slug="$(slugify "$label")"

resolve_db_path
enforce_safe_apply_db
if [[ ! -f "$db_path" ]]; then
  if [[ "$dry_run" == "true" ]]; then
    warn "Database not found (dry-run continues): $db_path"
  else
    die "Database not found: $db_path"
  fi
fi

if [[ "$apply_changes" == "true" && "$dry_run" != "true" && -f "$db_path" ]]; then
  pref_count_before="$(get_user_preference_count "$db_path")"
fi

emit_event \
  "stage=start" \
  "mode=$run_mode" \
  "db_path=$db_path" \
  "db_selection=$db_selection_note" \
  "session_pick_mode=$session_pick_mode" \
  "stale_hours=$stale_hours" \
  "scan_limit=$scan_limit"

if [[ "$list_session_candidates" == "true" ]]; then
  [[ -f "$db_path" ]] || die "Database not found: $db_path"
  if ! list_session_candidates_report; then
    die "Failed to list session candidates"
  fi
  emit_result_once \
    "status=success" \
    "mode=$run_mode" \
    "session_id=none" \
    "selection_reason=list-sessions-only" \
    "promoted_artifact=$promoted_artifact_state" \
    "project_scaffold=$project_scaffold_state" \
    "handoff_artifact=$handoff_artifact_state" \
    "artifacts_created=false" \
    "next_step=Run again without --list-sessions to generate report/apply workflow"
  exit 0
fi

if [[ "$single_session_mode" != "true" ]]; then
  [[ -f "$db_path" ]] || die "Database not found: $db_path"
  run_batch_mode
fi

if [[ -n "$session_id" ]]; then
  session_selection_note="provided via --session-id"
else
  [[ -f "$db_path" ]] || die "--session-id is required when database is unavailable"

  if ! inferred_line="$(infer_session_id)"; then
    die "Failed to infer session ID"
  fi
  IFS=$'\t' read -r session_id inferred_reason inferred_rows inferred_latest inferred_age <<< "$inferred_line"
  [[ -n "${inferred_reason:-}" ]] || die "Failed to infer session ID"

  # Robustly detect the "no sessions" sentinel returned by infer_session_id
  # (the helper prints a leading tab then a human string when empty).
  inferred_lower="$(printf '%s' "$inferred_reason" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "${session_id// /}" || "$inferred_lower" == *"no sessions found"* || "${inferred_rows:-}" == "unknown" ]]; then
    session_selection_note="no-sessions-found"
    emit_event \
      "stage=session-selected" \
      "mode=$run_mode" \
      "session_id=none" \
      "selection_reason=$session_selection_note"

    emit_result_once \
      "status=success" \
      "mode=$run_mode" \
      "session_id=none" \
      "selection_reason=$session_selection_note" \
      "promoted_artifact=$promoted_artifact_state" \
      "project_scaffold=$project_scaffold_state" \
      "handoff_artifact=$handoff_artifact_state" \
      "artifacts_created=false" \
      "next_step=No session data found; run with --list-sessions to inspect or capture session memory before --apply"
    exit 0
  fi

  [[ -n "$session_id" ]] || die "Unable to infer session ID: $inferred_reason"

  inferred_rows="${inferred_rows:-unknown}"
  inferred_latest="${inferred_latest:-unknown}"
  inferred_age="${inferred_age:-unknown}"
  session_selection_note="inferred: $inferred_reason"

  log "Inferred session ID: $session_id"
  log "Inference details: rows=$inferred_rows latest=$inferred_latest age_hours=$inferred_age mode=$session_pick_mode"
fi

  # Do not overwrite the canonical session_id used for DB lookups: some
  # session keys are case-sensitive or contain characters that must be
  # preserved when querying the SQLite store. Create a filesystem-safe
  # slug for use in filenames/artifact labels instead.
  session_id_slug="$(slugify "$session_id")"

emit_event \
  "stage=session-selected" \
  "mode=$run_mode" \
  "session_id=$session_id" \
  "selection_reason=$session_selection_note"

tmp_dir="$(mktemp -d)"
report_file="$tmp_dir/autodream-report.md"
summary_file="$tmp_dir/autodream-summary.txt"
compacted_signal_json_file="$tmp_dir/autodream-compacted-signal.json"
compacted_signal_md_file="$tmp_dir/autodream-compacted-signal.md"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if [[ "$dry_run" == "true" && ! -f "$db_path" ]]; then
  cat > "$report_file" <<EOF
# /autodream Report (V1)

- Session ID: \
  \
  $session_id

- Database: \
  \
  $db_path

- Session selection: \
  \
  $session_selection_note

- Note: database missing in dry-run mode; metrics unavailable.
EOF
  printf 'Dry-run preview only; no summary extracted.' > "$summary_file"
  cat > "$compacted_signal_json_file" <<EOF
{
  "schema_version": 1,
  "session_id": "$session_id",
  "label": "$label_slug",
  "status": "dry-run-no-db"
}
EOF
  cat > "$compacted_signal_md_file" <<EOF
# /autodream Compacted Signal (V1)

- Session ID: $session_id
- Status: dry-run-no-db
- Note: database missing in dry-run mode; compacted signal artifact is a preview placeholder only.
EOF
else
  if ! python3 - "$db_path" "$session_id" "$session_selection_note" "$report_file" "$summary_file" "$compacted_signal_json_file" "$compacted_signal_md_file" "$project_slug" "$topic_slug" <<'PY'
import sqlite3
import sys
import json
from collections import Counter
from datetime import datetime, timezone

db_path, session_id, selection_note, report_path, summary_path, compact_json_path, compact_md_path, project_slug, topic_slug = sys.argv[1:10]

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
tables = {
    row[0]
    for row in conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type='table'
          AND name IN ('session_contexts', 'interactions', 'tasks', 'work_sessions')
        """
    ).fetchall()
}

rows = []
source_counts = Counter()

def parse_ts(raw):
    if not raw:
        return None
    for candidate in (raw, raw.replace("Z", "+00:00")):
        try:
            dt = datetime.fromisoformat(candidate)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.timestamp()
        except ValueError:
            continue
    try:
        dt = datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        return dt.timestamp()
    except ValueError:
        return None

def add_record(record, source_name):
    rows.append(record)
    source_counts[source_name] += 1

if "session_contexts" in tables:
    session_rows = conn.execute(
        """
        SELECT context_type, key, value, updated_at
        FROM session_contexts
        WHERE session_id = ?
        ORDER BY updated_at DESC
        """,
        (session_id,),
    ).fetchall()
    for record in session_rows:
        add_record(
            {
                "context_type": record["context_type"],
                "key": record["key"],
                "value": record["value"],
                "updated_at": record["updated_at"] or "unknown",
            },
            "session_contexts",
        )

if "interactions" in tables:
    interaction_rows = conn.execute(
        """
        SELECT role, content, created_at
        FROM interactions
        WHERE session_id = ?
        ORDER BY created_at DESC
        """,
        (session_id,),
    ).fetchall()
    for index, record in enumerate(interaction_rows):
        add_record(
            {
                "context_type": f"interaction/{(record['role'] or 'unknown').lower()}",
                "key": f"message-{index + 1}",
                "value": record["content"] or "",
                "updated_at": record["created_at"] or "unknown",
            },
            "interactions",
        )

if "tasks" in tables:
    task_rows = conn.execute(
        """
        SELECT id, title, description, state, priority, phase, progress, created_at, started_at, finished_at
        FROM tasks
        WHERE workflow_id = ?
        ORDER BY created_at DESC
        """,
        (session_id,),
    ).fetchall()
    for record in task_rows:
        summary_bits = [
            f"title={record['title'] or 'untitled'}",
            f"state={record['state'] or 'unknown'}",
            f"priority={record['priority']}",
        ]
        if record["phase"]:
            summary_bits.append(f"phase={record['phase']}")
        if record["progress"] is not None:
            summary_bits.append(f"progress={record['progress']}%")
        if record["description"]:
            summary_bits.append(f"description={record['description']}")
        updated_at = record["finished_at"] or record["started_at"] or record["created_at"] or "unknown"
        add_record(
            {
                "context_type": f"task/{(record['state'] or 'unknown').lower()}",
                "key": f"task-{record['id']}",
                "value": " | ".join(summary_bits),
                "updated_at": updated_at,
            },
            "tasks",
        )

if "work_sessions" in tables:
    work_rows = conn.execute(
        """
        SELECT id, summary, started_at, ended_at, updated_at, created_at
        FROM work_sessions
        WHERE session_key = ?
        ORDER BY COALESCE(ended_at, updated_at, created_at, started_at) DESC
        """,
        (session_id,),
    ).fetchall()
    for record in work_rows:
        updated_at = record["ended_at"] or record["updated_at"] or record["created_at"] or record["started_at"] or "unknown"
        add_record(
            {
                "context_type": "work_session",
                "key": f"work-session-{record['id']}",
                "value": (record["summary"] or "").strip(),
                "updated_at": updated_at,
            },
            "work_sessions",
        )

conn.close()

if not rows:
    print(
        (
            "ERROR: no session rows found for session_id="
            f"{session_id} in session_contexts/interactions/tasks/work_sessions"
        ),
        file=sys.stderr,
    )
    raise SystemExit(1)

records = rows
records.sort(key=lambda item: parse_ts(item.get("updated_at")) or 0, reverse=True)
total = len(records)
type_counts = Counter((record.get("context_type") or "unknown") for record in records)
key_counts = Counter((record.get("key") or "(no-key)") for record in records)
latest = records[0].get("updated_at")
oldest = records[-1].get("updated_at")

## -- Semantic signal scoring (v2) --
## Multi-dimensional scoring replaces keyword-only heuristics.
## Each record is scored on: context_type weight, content density,
## recency, uniqueness, actionability, and bucket affinity.
import re
import math

now_ts = datetime.now(timezone.utc).timestamp()

# Context type weights: higher = more likely to be high-signal
CTYPE_WEIGHTS = {
    "decision": 1.0, "handoff": 1.0, "blocker": 0.95, "status": 0.7,
    "task": 0.8, "summary": 0.75, "work_session": 0.65, "workflow": 0.6,
    "convention": 0.5, "learning": 0.5, "routing_pattern": 0.3,
    "interaction/user": 0.4, "interaction/assistant": 0.3,
}

# Semantic patterns with weights — broader than literal keywords
SEMANTIC_PATTERNS = {
    "decisions": [
        (r"\b(decid|chose|select|pick|went with|approach|rationale|trade-?off|because)\b", 0.8),
        (r"\b(option [a-d]|alternative|vs\.?|versus|over|instead of)\b", 0.6),
        (r"\b(design|architect|pattern|strategy|direction)\b", 0.5),
    ],
    "blockers": [
        (r"\b(block|stuck|wait|depend|cannot|can't|unable|prevent|miss|fail|broken)\b", 0.8),
        (r"\b(need[s]? .{0,20}before|prerequisite|gat[ei]|requires?)\b", 0.7),
        (r"\b(error|exception|crash|timeout|reject|denied)\b", 0.5),
    ],
    "next_actions": [
        (r"\b(next|todo|follow[- ]?up|action item|then|should|must|need to)\b", 0.8),
        (r"\b(ship|deploy|merge|release|push|submit|create pr|open issue)\b", 0.7),
        (r"\b(implement|add|fix|update|refactor|migrate|test)\b", 0.5),
        (r"\b(step \d|phase \d|sprint|milestone|target)\b", 0.6),
    ],
    "learnings": [
        (r"\b(learn|discover|realize|found that|turns out|gotcha|caveat|insight)\b", 0.8),
        (r"\b(convention|pattern|best practice|anti-?pattern|pitfall)\b", 0.6),
        (r"\b(config|setup|install|bootstrap|environment)\b", 0.4),
    ],
}

def score_record(record):
    """Score a record across multiple signal dimensions. Returns (total_score, bucket_scores)."""
    ctype = (record.get("context_type") or "unknown").lower()
    key = (record.get("key") or "(no-key)").lower()
    value = (record.get("value") or "").strip()
    updated_at = record.get("updated_at") or ""
    searchable = f"{ctype} {key} {value}".lower()

    # Dimension 1: Context type weight (0-1)
    ctype_score = CTYPE_WEIGHTS.get(ctype, 0.0)
    for prefix, weight in CTYPE_WEIGHTS.items():
        if ctype.startswith(prefix):
            ctype_score = max(ctype_score, weight)

    # Dimension 2: Content density — longer, structured content = more signal
    word_count = len(value.split())
    has_structure = bool(re.search(r"[-*]\s|^\d+\.", value, re.MULTILINE))
    has_code = bool(re.search(r"`[^`]+`|```|\b(function|class|def|import|export)\b", value))
    density_score = min(1.0, (word_count / 60.0) * 0.6 + (0.2 if has_structure else 0) + (0.2 if has_code else 0))

    # Dimension 3: Recency decay (exponential, half-life = 7 days)
    record_ts = parse_ts(updated_at)
    if record_ts and now_ts > 0:
        age_days = max(0, (now_ts - record_ts) / 86400.0)
        recency_score = math.exp(-0.099 * age_days)  # half-life ~7 days
    else:
        recency_score = 0.3  # unknown timestamp penalty

    # Dimension 4: Uniqueness — penalize keys that appear many times (noisy)
    key_freq = key_counts.get(key, 1)
    uniqueness_score = 1.0 / (1.0 + math.log(max(1, key_freq)))

    # Dimension 5: Semantic bucket affinity — pattern matching with weights
    bucket_scores = {}
    for bucket_name, patterns in SEMANTIC_PATTERNS.items():
        bucket_max = 0.0
        for pattern, weight in patterns:
            if re.search(pattern, searchable, re.IGNORECASE):
                bucket_max = max(bucket_max, weight)
        bucket_scores[bucket_name] = bucket_max

    actionability_score = max(bucket_scores.values()) if bucket_scores else 0.0

    # Composite score: weighted combination
    total = (
        ctype_score * 0.20
        + density_score * 0.15
        + recency_score * 0.20
        + uniqueness_score * 0.15
        + actionability_score * 0.30
    )

    return total, bucket_scores

# Score all records
scored_records = []
for record in records:
    total_score, bucket_scores = score_record(record)
    scored_records.append((total_score, bucket_scores, record))

# Sort by score descending, deduplicate
scored_records.sort(key=lambda x: x[0], reverse=True)

high_signal = []
seen = set()
for total_score, bucket_scores, record in scored_records:
    ctype = record.get("context_type") or "unknown"
    key = record.get("key") or "(no-key)"
    dedupe = (ctype, key)
    if dedupe in seen:
        continue
    seen.add(dedupe)
    record["_score"] = round(total_score, 4)
    record["_bucket_scores"] = {k: round(v, 3) for k, v in bucket_scores.items() if v > 0}
    high_signal.append(record)
    if len(high_signal) >= 25:
        break

if not high_signal:
    high_signal = records[:10]

noisy_keys = [(key, count) for key, count in key_counts.most_common(8) if count >= 3]

# Bucket assignment using semantic scores — a record can match multiple buckets
BUCKET_THRESHOLD = 0.4
signal_buckets = {"decisions": [], "blockers": [], "next_actions": [], "learnings": []}

for record in high_signal:
    ctype = (record.get("context_type") or "unknown").lower()
    value = (record.get("value") or "").strip()
    compact_value = value.replace("\n", " ").strip()
    if len(compact_value) > 220:
        compact_value = compact_value[:217] + "..."

    compact_record = {
        "updated_at": record.get("updated_at") or "unknown",
        "context_type": record.get("context_type") or "unknown",
        "key": record.get("key") or "(no-key)",
        "value": compact_value,
        "score": record.get("_score", 0),
    }

    bucket_scores = record.get("_bucket_scores", {})
    matched = False
    for bucket_name in signal_buckets:
        if bucket_scores.get(bucket_name, 0) >= BUCKET_THRESHOLD:
            signal_buckets[bucket_name].append(compact_record)
            matched = True
    # Fallback: task types go to next_actions
    if not matched and ctype.startswith("task/"):
        signal_buckets["next_actions"].append(compact_record)

for bucket_name in signal_buckets:
    deduped = []
    seen_b = set()
    for record in signal_buckets[bucket_name]:
        dedupe_key = (record["context_type"], record["key"], record["value"])
        if dedupe_key in seen_b:
            continue
        seen_b.add(dedupe_key)
        deduped.append(record)
    signal_buckets[bucket_name] = deduped[:10]

# Compute scoring stats for metrics
score_values = [s[0] for s in scored_records]
scoring_stats = {
    "algorithm": "semantic-v2",
    "total_scored": len(scored_records),
    "high_signal_count": len(high_signal),
    "mean_score": round(sum(score_values) / len(score_values), 4) if score_values else 0,
    "max_score": round(max(score_values), 4) if score_values else 0,
    "min_score": round(min(score_values), 4) if score_values else 0,
    "bucket_counts": {k: len(v) for k, v in signal_buckets.items()},
    "threshold": BUCKET_THRESHOLD,
}

compacted_payload = {
    "schema_version": 2,
    "artifact": "autodream-compacted-signal",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "session_id": session_id,
    "selection": {
        "note": selection_note,
    },
    "scoring": scoring_stats,
    "totals": {
        "rows": total,
        "distinct_context_types": len(type_counts),
        "source_counts": dict(sorted(source_counts.items())),
        "latest_update": latest,
        "oldest_update": oldest,
    },
    "top_context_types": [{"context_type": ctype, "count": count} for ctype, count in type_counts.most_common(8)],
    "signal": {
        "high_signal_candidates": [
            {
                "updated_at": record.get("updated_at") or "unknown",
                "context_type": record.get("context_type") or "unknown",
                "key": record.get("key") or "(no-key)",
                "value": (record.get("value") or "").strip().replace("\n", " ")[:300],
                "score": record.get("_score", 0),
            }
            for record in high_signal[:25]
        ],
        "decisions": signal_buckets["decisions"],
        "blockers": signal_buckets["blockers"],
        "next_actions": signal_buckets["next_actions"],
        "learnings": signal_buckets["learnings"],
        "noisy_keys": [{"key": key, "updates": count} for key, count in noisy_keys],
    },
}

lines = [
    "# /autodream Report (V2)",
    "",
    "## Session Snapshot",
    "",
    f"- Session ID: `{session_id}`",
    f"- Session selection: `{selection_note}`",
    f"- Data sources (rows): `{', '.join(f'{name}:{count}' for name, count in sorted(source_counts.items()))}`",
    f"- Total context rows: `{total}`",
    f"- Distinct context types: `{len(type_counts)}`",
]

if latest:
    lines.append(f"- Latest update: `{latest}`")
if oldest:
    lines.append(f"- Oldest update: `{oldest}`")

lines.extend([
    "",
    "## Compaction View",
    "",
    "Context type frequency (descending):",
])

for ctype, count in type_counts.most_common():
    lines.append(f"- `{ctype}`: {count}")

lines.extend([
    "",
    "High-signal candidate records (semantic-v2 scored, latest unique keys):",
])

for record in high_signal:
    ctype = record.get("context_type") or "unknown"
    key = record.get("key") or "(no-key)"
    value = (record.get("value") or "").strip().replace("\n", " ")
    if len(value) > 160:
        value = value[:157] + "..."
    updated_at = record.get("updated_at") or "unknown"
    score = record.get("_score", 0)
    lines.append(f"- [{score:.3f}] `{updated_at}` [{ctype}] `{key}` - {value}")

if noisy_keys:
    lines.extend([
        "",
        "Potentially noisy keys (3+ updates):",
    ])
    for key, count in noisy_keys:
        lines.append(f"- `{key}`: {count} updates")

lines.extend([
    "",
    "## Scoring Summary (semantic-v2)",
    "",
    f"- Algorithm: `{scoring_stats['algorithm']}`",
    f"- Total records scored: `{scoring_stats['total_scored']}`",
    f"- High-signal count: `{scoring_stats['high_signal_count']}`",
    f"- Score range: `{scoring_stats['min_score']}` - `{scoring_stats['max_score']}` (mean: `{scoring_stats['mean_score']}`)",
    f"- Bucket counts: {', '.join(f'`{k}`: {v}' for k, v in scoring_stats['bucket_counts'].items())}",
])

summary = (
    f"Autodream V2 compacted {total} session rows for {session_id}; "
    f"scoring=semantic-v2 (mean={scoring_stats['mean_score']}, max={scoring_stats['max_score']}); "
    f"sources={','.join(sorted(source_counts.keys()))}; "
    f"buckets: {', '.join(f'{k}={v}' for k, v in scoring_stats['bucket_counts'].items())}."
)

with open(report_path, "w", encoding="utf-8") as handle:
    handle.write("\n".join(lines) + "\n")

with open(summary_path, "w", encoding="utf-8") as handle:
    handle.write(summary + "\n")

with open(compact_json_path, "w", encoding="utf-8") as handle:
    handle.write(json.dumps(compacted_payload, indent=2) + "\n")

compact_lines = [
    "---",
    "artifact_type: autodream-compacted-signal",
    f"session_id: {session_id}",
    f"project: {project_slug or 'general'}",
    f"topic: {topic_slug or 'autodream'}",
    f"generated_at: {compacted_payload['generated_at']}",
    "source: autodream-memory",
    "---",
    "",
    "# /autodream Compacted Signal (V2)",
    "",
    f"- Session ID: `{session_id}`",
    f"- Session selection: `{selection_note}`",
    f"- Total rows analyzed: `{total}`",
    f"- Top context types: `{', '.join([k for k, _ in type_counts.most_common(5)])}`",
    "",
    "## Decisions",
    "",
]

if signal_buckets["decisions"]:
    for item in signal_buckets["decisions"]:
        compact_lines.append(f"- [{item.get('score', 0):.3f}] `{item['updated_at']}` [{item['context_type']}] `{item['key']}` - {item['value']}")
else:
    compact_lines.append("- _No clear decision records extracted._")

compact_lines.extend(["", "## Blockers", ""])
if signal_buckets["blockers"]:
    for item in signal_buckets["blockers"]:
        compact_lines.append(f"- [{item.get('score', 0):.3f}] `{item['updated_at']}` [{item['context_type']}] `{item['key']}` - {item['value']}")
else:
    compact_lines.append("- _No active blockers extracted._")

compact_lines.extend(["", "## Next Actions", ""])
if signal_buckets["next_actions"]:
    for item in signal_buckets["next_actions"]:
        compact_lines.append(f"- [{item.get('score', 0):.3f}] `{item['updated_at']}` [{item['context_type']}] `{item['key']}` - {item['value']}")
else:
    compact_lines.append("- _No explicit next actions extracted._")

compact_lines.extend(["", "## Learnings", ""])
if signal_buckets["learnings"]:
    for item in signal_buckets["learnings"]:
        compact_lines.append(f"- [{item.get('score', 0):.3f}] `{item['updated_at']}` [{item['context_type']}] `{item['key']}` - {item['value']}")
else:
    compact_lines.append("- _No learnings/conventions extracted._")

if noisy_keys:
    compact_lines.extend(["", "## Noise to De-prioritize", ""])
    for key, count in noisy_keys:
        compact_lines.append(f"- `{key}` appeared `{count}` times")

with open(compact_md_path, "w", encoding="utf-8") as handle:
    handle.write("\n".join(compact_lines) + "\n")
PY
  then
    die "Failed to generate autodream compaction report"
  fi
fi

log ""
cat "$report_file"
log ""

if [[ "$apply_changes" != "true" ]]; then
  log "Report-only mode complete."
  log "Next step: rerun with --apply to promote artifacts."
  record_autodream_metrics 0
  emit_result_once \
    "status=success" \
    "mode=$run_mode" \
    "session_id=$session_id" \
    "selection_reason=$session_selection_note" \
    "promoted_artifact=$promoted_artifact_state" \
    "project_scaffold=$project_scaffold_state" \
    "handoff_artifact=$handoff_artifact_state" \
    "artifacts_created=false" \
    "next_step=Rerun with --apply to promote durable artifacts"
  exit 0
fi

apply_start_seconds=$SECONDS

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
promote_script="$script_dir/../../session-memory-mcp/scripts/promote-session-memory.sh"
init_script="$script_dir/init-memory-project.sh"
handoff_script="$script_dir/generate-memory-handoff-summary.sh"

[[ -x "$promote_script" ]] || die "Missing executable helper: $promote_script"
[[ -x "$init_script" ]] || die "Missing executable helper: $init_script"
[[ -x "$handoff_script" ]] || die "Missing executable helper: $handoff_script"

promote_cmd=("$promote_script" "--session-id" "$session_id" "--label" "$label_slug" "--db" "$db_path" "--agents-home" "$agents_home")
if [[ "$dry_run" == "true" ]]; then
  promote_cmd+=("--dry-run")
  promoted_artifact_state="preview-only"
else
  promoted_artifact_state="created"
fi

log "Running promotion helper..."
if ! "${promote_cmd[@]}"; then
  die "Promotion helper failed"
fi

log "Writing compacted high-signal artifact..."
write_compacted_signal_artifacts "$compacted_signal_json_file" "$compacted_signal_md_file"
run_optional_summarizer

if [[ -z "$project_slug" ]]; then
  log "WARN: --project not provided; skipping project scaffold and handoff record"
  apply_duration_ms=$(( (SECONDS - apply_start_seconds) * 1000 ))
  record_autodream_metrics "$apply_duration_ms"
  # Only prune if promoted_keep is >= 0 (0 means disable pruning)
if [[ "$promoted_keep" -ge 0 ]]; then
  prune_promoted_artifacts "$promoted_keep"
else
  log "Promoted retention: unlimited (no decay)"
fi
  verify_preferences_unchanged
  emit_result_once \
    "status=success" \
    "mode=$run_mode" \
    "session_id=$session_id" \
    "selection_reason=$session_selection_note" \
    "promoted_artifact=$promoted_artifact_state" \
    "project_scaffold=$project_scaffold_state" \
    "handoff_artifact=$handoff_artifact_state" \
    "artifacts_created=$([[ "$promoted_artifact_state" == "created" ]] && printf 'true' || printf 'false')" \
    "next_step=Optionally rerun with --project <slug> to write project scaffold and handoff linkage"
  exit 0
fi

init_cmd=("$init_script" "--project" "$project_slug" "--agents-home" "$agents_home")
if [[ "$dry_run" == "true" ]]; then
  init_cmd+=("--dry-run")
  project_scaffold_state="preview-only"
else
  project_scaffold_state="ensured"
fi

log "Ensuring project memory scaffold..."
if ! "${init_cmd[@]}"; then
  die "Project scaffold helper failed"
fi

populate_project_files_from_signal

handoff_summary="${summary_override:-$(<"$summary_file")}"
handoff_cmd=(
  "$handoff_script"
  "--project" "$project_slug"
  "--session-id" "$session_id"
  "--topic" "$topic_slug"
  "--summary" "$handoff_summary"
  "--db" "$db_path"
  "--agents-home" "$agents_home"
)
if [[ "$dry_run" == "true" ]]; then
  handoff_cmd+=("--dry-run")
  handoff_artifact_state="preview-only"
else
  handoff_artifact_state="created"
fi

log "Writing handoff summary linkage..."
if ! "${handoff_cmd[@]}"; then
  die "Handoff helper failed"
fi

publish_project_autodream_artifact_note

# Record metrics (non-fatal on failure)
apply_duration_ms=$(( (SECONDS - apply_start_seconds) * 1000 ))
record_autodream_metrics "$apply_duration_ms"

# Prune old promoted artifacts (keep 5 most recent sets)
# Only prune if promoted_keep is >= 0 (0 means disable pruning)
if [[ "$promoted_keep" -ge 0 ]]; then
  prune_promoted_artifacts "$promoted_keep"
else
  log "Promoted retention: unlimited (no decay)"
fi

log "Autodream V2 apply workflow complete."
verify_preferences_unchanged
emit_result_once \
  "status=success" \
  "mode=$run_mode" \
  "session_id=$session_id" \
  "selection_reason=$session_selection_note" \
  "promoted_artifact=$promoted_artifact_state" \
  "project_scaffold=$project_scaffold_state" \
  "handoff_artifact=$handoff_artifact_state" \
  "artifacts_created=$([[ "$run_mode" == "apply" ]] && printf 'true' || printf 'false')" \
  "next_step=Review created artifacts and continue with normal workflow"
