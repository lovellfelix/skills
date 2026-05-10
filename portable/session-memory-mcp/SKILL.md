---
name: session-memory-mcp
description: Use when preserving cross-session workflow context, tracking in-flight tasks, or promoting durable handoff artifacts across agent runs.
metadata:
  version: 0.3.2
  portable: true
  tags: [mcp, memory, workflow, continuity]
---

# Session Memory MCP

Use session-memory as a durable context layer so sessions resume quickly without noise or re-discovery.

## Use when

- Cross-session continuity matters for active engineering work.
- You need to persist decisions, blockers, or next actions.
- A workflow has many steps and context can drift.
- Coordinating multiple agents or handoffs.

## Do not use when

- Data is transient with no value past the current response.
- Information is sensitive and must not be stored.
- You would store duplicated low-signal output (raw logs, command spam).

**Never store secrets/tokens/credentials/private personal data** in session, workflow, or durable memory records.

## Store-or-skip filter

Store only when at least one is true:

- Changes future decisions.
- Captures a blocker, assumption, or dependency.
- Records a non-obvious project convention.
- Enables restart without repeating discovery.

Skip if it is pure command output, redundant status, or temporary reasoning.

## Core patterns

### Session context records

Prefer small records with predictable keys:

- `key`: stable lookup key (`task:auth-refactor`, `decision:path-layout`).
- `contextType`: `workflow` · `decision` · `blocker` · `convention` · `handoff` · `interaction`.
- `value`: Situation + Decision + Next (3-line structure).
- `metadataJson`: optional JSON string (owner, due date, links, confidence).

### Project conventions

Store separately from per-session updates:

- Stable patterns (naming, commit style, test commands) → convention records.
- Current execution state → session context records.

### Retrieval strategy

At session start (first turn):

1. Durable context is auto-injected from `durable_memory` — read and apply it.
2. Retrieve open blockers and in-progress tasks via `workflow_tasks`.
3. Query session memory only if prior context has a specific lookup key.

During execution:

- Re-query only when context changed or uncertainty increased.
- Prefer narrow queries over broad dumps.

At handoff:

- Write one summary record pointing to key context keys and durable file paths.
- Keep `projects/<project>/current.md` and the latest handoff packet aligned.

## Tool mapping (Pi and similar harnesses)

In Pi, memory surfaces are split by role. Use this mapping and translate to equivalent tools in other harnesses:

| Need                                            | Tool                 |
| ----------------------------------------------- | -------------------- |
| Active working context (live session)           | `session_memory`     |
| Task state and progress tracking                | `workflow_tasks`     |
| On-disk promoted summaries, handoffs, autodream | `durable_memory`     |
| Work notes / runbooks in `~/knowledgebase`      | `work_knowledgebase` |

Key `session_memory` actions:

- `store_context` — write a workflow/decision/blocker record.
- `retrieve_context` — targeted read by key or type.
- `track_user_preference` — persist a user style or workflow preference (silent).
- `learn_project_convention` — record a stable project pattern.
- `assemble_context` — pull active context for resume/continue signals.
- `get_user_preferences` — read preferences before style decisions.

## Practical examples

Note: exact argument names are harness-specific; confirm the active tool schema before calling memory tools.

### Example: store_context for an in-flight blocker

Use `session_memory.store_context` when work should resume in the same project/session stream:

```json
{
  "action": "store_context",
  "contextType": "blocker",
  "key": "api:migration:blocker:missing-scope",
  "value": "Situation: OAuth scope missing for write endpoint.\nDecision: pause write-tool rollout.\nNext: request scope update and re-test.",
  "metadataJson": "{\"owner\":\"platform\",\"priority\":\"high\"}"
}
```

### Example: retrieve + assemble before resuming work

Use `workflow_tasks` for task status, then `session_memory` for targeted context:

```text
1) workflow_tasks action=list status=in_progress -> find in_progress item IDs (or omit filters to list current session tasks)
2) session_memory.retrieve_context(key=task:<id>)
3) session_memory.assemble_context(query="resume auth refactor") if continuity is unclear — confirm the active MCP schema before calling
```

### When to use which memory surface

- `session_memory`: active decisions, blockers, conventions, preferences.
- `workflow_tasks`: task lifecycle state (queued/in_progress/done/fail).
- `durable_memory`: promoted handoffs, compact summaries, cross-session artifacts.

## Path conventions

```text
~/.agents/memory/session.db          # working layer (session_memory)
~/.agents/memory/projects/<project>/ # project-scoped durable state
~/.agents/memory/handoffs/YYYY/MM/   # handoff packets
~/.agents/memory/promoted/           # promoted exports + compact summaries
~/.agents/memory/profile/            # identity and preferences
~/.agents/memory/people/             # local-only people context
```

When reading durable artifacts, prefer:

1. `projects/<project>/artifacts/autodream-*-latest.md`
2. `promoted/*-compact.md`
3. `handoffs/YYYY/MM/*.md`

## Autodream promotion

Autodream runs automatically:

- After each `agent_end` (throttled to 1h) and on `session_shutdown`.
- Mode defaults to `apply` (writes to disk).
- Trigger manually: `durable_memory` tool with `autodream_apply`.
- Override: `PI_DURABLE_MEMORY_AUTO_MODE=report|apply|off`.

## Fallback: MCP unavailable

When the MCP server is unreachable (different harness, CLI context, or server not running), you can either use the repository-provided helper script (if present) or query the SQLite DB directly with local tools.

If this dotfiles layout includes the convenience helper, it lives at `~/.dotfiles/hacks/smem.sh` and provides simple commands, for example:

```bash
# Portable CLI — repo-provided helper (only present if your dotfiles include it)
~/.dotfiles/hacks/smem.sh sessions                        # list known session IDs
~/.dotfiles/hacks/smem.sh list [session_id]               # recent context records
~/.dotfiles/hacks/smem.sh get <key> [session_id]          # read a value by key
~/.dotfiles/hacks/smem.sh set <type> <key> <value> [sid]  # write / upsert a record
~/.dotfiles/hacks/smem.sh tasks [workflow_id]             # workflow task state
~/.dotfiles/hacks/smem.sh prefs                           # user preferences
~/.dotfiles/hacks/smem.sh conventions [project_id]        # project conventions
~/.dotfiles/hacks/smem.sh search <query> [session_id]     # full-text search
~/.dotfiles/hacks/smem.sh dump [session_id]               # all records for session
```

If the helper is not available, inspect or query the SQLite DB directly with tools you already have (sqlite3, a DB browser, or other CLI utilities). For example:

```bash
# Example direct SQLite queries (adjust path if your session DB is elsewhere)
sqlite3 ~/.agents/memory/session.db "SELECT key, contextType, value FROM records LIMIT 20;"
# or open an interactive shell:
sqlite3 ~/.agents/memory/session.db
sqlite> .tables
sqlite> SELECT * FROM records WHERE key LIKE '%auth%';
```

Override DB path when needed: `SESSION_DB=/path/to/session.db smem.sh list`

Use the helper when the harness has no MCP tools configured (Cursor, Copilot, raw shell), for debugging session memory content outside of an agent session, or when scripting batch reads/writes from shell automation.

## Validation checks

After writes, verify memory flow worked:

1. Read back the same key with `retrieve_context` and confirm Situation/Decision/Next matches.
2. Confirm related task state exists in `workflow_tasks` (if task-tracked).
3. For promoted artifacts, verify expected file exists under `~/.agents/memory/projects/<project>/` or `~/.agents/memory/handoffs/...`.
4. If MCP path is unavailable, verify via `~/.dotfiles/hacks/smem.sh get <key>`.

## Noise control

- Merge overlapping notes into one updated record.
- Avoid near-duplicate keys.
- Archive or prune stale records that no longer inform decisions.
- Keep records short enough to scan in 5 seconds.
