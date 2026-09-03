---
name: session-memory-mcp
description: Use when preserving cross-session workflow context, tracking in-flight tasks, or promoting durable handoff artifacts across agent runs.
metadata:
  version: 0.3.4
  portable: true
  tags: [mcp, memory, workflow, continuity]
---

# Session Memory MCP (LeanCTX-Backed)

Use session-memory as a durable context layer so sessions resume quickly without noise or re-discovery. **Backend varies by harness — confirm before assuming.** On Claude Code, `session_memory` is the real standalone MCP server running directly against its own SQLite database (`~/.agents/memory/session.db`); this is the primary store there, not a facade over LeanCTX (per the 2026-07-09 status update in `docs/plans/2026-06-04-session-memory-leanctx-migration.md` — Claude Code deliberately kept it wired directly). Pi instead routes `workflow_tasks` and related state through LeanCTX (`ctx_knowledge`, `ctx_session`, `ctx_task`, `ctx_workflow`) rather than a live session-memory server.

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

**IDs:** `project_id` = git repo basename (e.g. `"dotfiles"`); `session_id` = `"personal-assistant"` for conversational sessions. `assemble_active_context` searches across all harnesses regardless of `session_id`.

At session start (first turn):

1. Read LeanCTX project facts and active context first.
2. Use `durable_memory` only as a fallback when the relevant project facts or handoff details are not yet available in LeanCTX.
3. Retrieve open blockers and in-progress tasks via `workflow_tasks` (LeanCTX-backed `ctx_task`/`ctx_workflow`).
4. Query session memory only if prior context has a specific lookup key (LeanCTX-backed `ctx_knowledge`/`ctx_session`).

During execution:

- Re-query only when context changed or uncertainty increased.
- Prefer narrow queries over broad dumps.

At handoff:

- Write one summary record pointing to key context keys and durable file paths.
- Keep `projects/<project>/current.md` and the latest handoff packet aligned.

## Token budget and cross-harness guidance

The `session_memory` compatibility facade exposes 60+ actions (all LeanCTX-backed). Not all harnesses need the full surface — injecting 60 tool definitions into every session wastes context budget and slows inference.

**Use only these core tools in normal sessions:**

| Tool                                        | Purpose                                         |
| ------------------------------------------- | ----------------------------------------------- |
| `store_session_context`                     | Write a workflow/decision/blocker record        |
| `retrieve_session_context`                  | Read by key or type                             |
| `update_session_context`                    | Append without overwriting                      |
| `assemble_active_context`                   | Pull full active context for resume/continue    |
| `track_user_preference`                     | Persist a style or workflow preference (silent) |
| `get_user_preferences`                      | Read preferences before style decisions         |
| `learn_project_convention`                  | Record a stable project pattern                 |
| `get_project_conventions`                   | Read conventions before pattern-sensitive work  |
| `create_task` / `get_tasks` / `update_task` | Task lifecycle                                  |
| `search_memories`                           | FTS5 search across all records                  |
| `server_health`                             | Check MCP availability                          |

**Avoid in token-constrained contexts:** API spec tools (`store_api_spec`, `get_api_endpoints`, etc.), analytics (`analysis_memory_map`, `analysis_conflicts`), routing pattern tools, batch tools, and the web dashboard. These are maintenance surfaces, not runtime tools.

**CLI-first for non-agent tasks:** For shell scripts, hooks, and inspection outside an agent session, prefer the built-in CLI over starting an MCP session:

```bash
# LeanCTX CLI (source of truth)
lean-ctx knowledge export --format json          # export all facts/preferences
lean-ctx task list                                # list tasks (requires `lean-ctx serve`)
lean-ctx session status                           # session status

# Legacy smem.sh fallback (queries legacy SQLite; not source of truth)
scripts/smem.sh sessions
scripts/smem.sh list [session_id]
scripts/smem.sh search <term>
scripts/smem.sh prefs
```

Use the CLI for: startup hooks, post-session summaries, cron-based cleanup, shell aliases that query memory, and debugging data without consuming agent context.

**Cross-harness note:** Claude Code and OpenCode load session_memory as a LeanCTX-backed MCP tool. Cursor and Copilot should use the CLI or skip MCP entirely — the token overhead is not justified for those harnesses unless you restrict to the core 11 tools above.

## Tool mapping (Pi and similar harnesses)

In Pi, memory surfaces are split by role. Use this mapping and translate to equivalent tools in other harnesses:

| Need                                                       | Tool                             | Backend                           |
| ---------------------------------------------------------- | -------------------------------- | --------------------------------- |
| Active working context (live session)                      | `session_memory`                 | LeanCTX `ctx_session`             |
| Task board & task insights (`task_board`, `task_insights`) | `workflow_tasks`                 | LeanCTX `ctx_task`/`ctx_workflow` |
| Task state and progress tracking                           | `workflow_tasks`                 | LeanCTX `ctx_task`/`ctx_workflow` |
| On-disk promoted summaries and handoffs                    | `durable_memory` (fallback only) | filesystem                        |
| Durable work notes / runbooks in `~/llm-wiki`              | `llm-wiki` (export/archive)      | filesystem                        |

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

Use `workflow_tasks` (LeanCTX-backed) for task status, then `session_memory` (LeanCTX-backed) for targeted context:

```text
1) workflow_tasks action=list status=in_progress -> find in_progress item IDs (or omit filters to list current session tasks)
2) session_memory.retrieve_context(key=task:<id>)
3) session_memory.assemble_context(query="resume auth refactor") if continuity is unclear — confirm the active MCP schema before calling
```

### When to use which memory surface

- `session_memory` (LeanCTX-backed): active decisions, blockers, conventions, preferences.
- `workflow_tasks` (LeanCTX-backed): task lifecycle state (queued/in_progress/done/fail).
- `durable_memory` — fallback reader for raw handoff artifacts not yet in LeanCTX.
- `llm-wiki` — export/archive surface for human-readable project notes, not the canonical runtime store.

## Path conventions

```text
~/.agents/memory/session.db          # legacy/rollback layer (SQLite; not source of truth)
~/.agents/memory/projects/<project>/ # project-scoped durable state
~/.agents/memory/handoffs/YYYY/MM/   # handoff packets
~/.agents/memory/promoted/           # promoted exports + compact summaries
~/.agents/memory/profile/            # identity and preferences
~/.agents/memory/people/             # local-only people context

On Claude Code, this SQLite database is the active runtime store for preferences, conventions, contexts, and task state — not a legacy rollback path. On Pi, most of this instead routes through LeanCTX (`ctx_knowledge`/`ctx_task`/`ctx_workflow`). Confirm which mode applies for the current harness before treating either as authoritative.
```

When reading durable artifacts, prefer:

1. `projects/<project>/artifacts/*-latest.md`
2. `promoted/*-compact.md`
3. `handoffs/YYYY/MM/*.md`

## Durable promotion

Promote session memory to durable artifacts manually or via explicit tooling; Pi does not automatically trigger promotions.

- Manual (recommended): `scripts/promote-session-memory.sh --session-id <session-id>`
- Via MCP helper: use the `LeanCTX` tool or the repo-provided promotion scripts with explicit `--apply` to write artifacts.
- Use `--dry-run` to preview actions before writing promoted files under `~/.agents/memory/promoted/`.

## Fallback: MCP unavailable

When the LeanCTX MCP server is unreachable (different harness, CLI context, or server not running), you can either use the repository-provided helper script (if present) or query the legacy SQLite DB directly as a fallback. SQLite is not the source of truth — it is a legacy rollback path.

This skill bundles a convenience helper at `scripts/smem.sh`, which provides simple commands, for example:

```bash
# Portable CLI — bundled with this skill
scripts/smem.sh sessions                        # list known session IDs
scripts/smem.sh list [session_id]               # recent context records
scripts/smem.sh get <key> [session_id]          # read a value by key
scripts/smem.sh set <type> <key> <value> [sid]  # write / upsert a record
scripts/smem.sh tasks [workflow_id]             # workflow task state
scripts/smem.sh prefs                           # user preferences
scripts/smem.sh conventions [project_id]        # project conventions
scripts/smem.sh search <query> [session_id]     # full-text search
scripts/smem.sh dump [session_id]               # all records for session
```

If the helper is not available, inspect or query the legacy SQLite DB directly as a fallback (not source of truth) with tools you already have (sqlite3, a DB browser, or other CLI utilities). For example:

```bash
# Example direct SQLite queries (legacy fallback; LeanCTX MCP is preferred)
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
2. Confirm related task state exists in `workflow_tasks` (LeanCTX-backed; if task-tracked).
3. For promoted artifacts, verify expected file exists under `~/.agents/memory/projects/<project>/` or `~/.agents/memory/handoffs/...`.
4. If MCP path is unavailable, verify via `scripts/smem.sh get <key>`.

## Noise control

- Merge overlapping notes into one updated record.
- Avoid near-duplicate keys.
- Archive or prune stale records that no longer inform decisions.
- Keep records short enough to scan in 5 seconds.
