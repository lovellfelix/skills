---
name: session-memory-mcp
description: Practical patterns for storing, retrieving, and maintaining high-signal session memory via MCP. Use when building MCP-integrated workflows, caching session state, or establishing durable patterns across sessions.
version: 0.2.0
portable: true
tags: [mcp, memory, workflow, continuity, portable]
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
- `context_key`: stable lookup key (`task:auth-refactor`, `decision:path-layout`).
- `context_type`: `workflow` · `decision` · `blocker` · `convention` · `handoff` · `interaction`.
- `context_value`: Situation + Decision + Next (3-line structure).
- `metadata`: optional JSON (owner, due date, links, confidence).

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

## Pi tool mapping

In Pi, session memory is split by role — use the right surface:

| Need | Tool |
|------|------|
| Active working context (live session) | `session_memory` |
| Task state and progress tracking | `workflow_tasks` |
| On-disk promoted summaries, handoffs, autodream | `durable_memory` |
| Work notes / runbooks in `~/knowledgebase` | `work_knowledgebase` |

Key `session_memory` actions:
- `store_context` — write a workflow/decision/blocker record.
- `retrieve_context` — targeted read by key or type.
- `track_user_preference` — persist a user style or workflow preference (silent).
- `learn_project_convention` — record a stable project pattern.
- `assemble_context` — pull active context for resume/continue signals.
- `get_user_preferences` — read preferences before style decisions.

## Path conventions

```
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

When the MCP server is unreachable (different harness, CLI context, or server not running), use the SQLite CLI fallback directly against `~/.agents/memory/session.db`:

```bash
# Portable CLI — no MCP required
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

Override DB path: `SESSION_DB=/path/to/session.db smem.sh list`

Use `smem.sh` when:
- Harness has no MCP tools configured (Cursor, Copilot, raw shell).
- Debugging session memory content outside of an agent session.
- Scripting batch reads or writes from shell automation.

- Merge overlapping notes into one updated record.
- Avoid near-duplicate keys.
- Archive or prune stale records that no longer inform decisions.
- Keep records short enough to scan in 5 seconds.
## Noise control

- Merge overlapping notes into one updated record.
- Avoid near-duplicate keys.
- Archive or prune stale records that no longer inform decisions.
- Keep records short enough to scan in 5 seconds.
