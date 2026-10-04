---
name: session-memory-mcp
description: Use when preserving cross-session workflow context, tracking in-flight tasks, recording decisions/blockers/conventions/preferences, or promoting durable handoff artifacts across agent runs via the session_memory MCP or its CLI fallback.
metadata:
  version: 0.4.1
  portable: true
  tags: [mcp, memory, workflow, continuity, leanctx]
---

# Session Memory MCP

A small durable context layer so sessions resume without re-discovery. Store decisions, not transcripts.

Related: `handoff-resume` (resume/handoff workflow built on this), `llm-wiki-workflow` (human-readable export layer), `lean-ctx` (LeanCTX tooling).

## Backend depends on the harness

Confirm which applies before treating a store as authoritative:

| Harness            | `session_memory` backend                                               | Tasks                                       |
| ------------------ | ---------------------------------------------------------------------- | ------------------------------------------- |
| Claude Code        | Standalone MCP server on SQLite `~/.agents/memory/session.db` (primary) | `create_task` / `get_tasks` / `update_task` |
| Pi                 | LeanCTX (`ctx_session`, `ctx_knowledge`)                                | `workflow_tasks` → `ctx_task`/`ctx_workflow` |
| OpenCode           | Check the active MCP config; treat like Pi if LeanCTX-backed            | same as backend                             |
| Cursor, Copilot, shell | No MCP; use `scripts/smem.sh` (SQLite) or `lean-ctx` CLI            | CLI                                         |

Status as of the 2026-07-09 update in `dotfiles`' `docs/plans/2026-06-04-session-memory-leanctx-migration.md`: Claude Code deliberately kept the direct SQLite server. Re-check that doc if behavior looks different.

Tool and argument names differ by harness. Claude Code exposes separate tools (`store_session_context`, `retrieve_session_context`, …). Pi and LeanCTX-backed harnesses expose one `session_memory` tool with an `action` (`store_context`, `retrieve_context`, `assemble_context`, …). Examples below use the action form; map to the tool name your harness lists, and check the live schema before calling.

## Store or skip

**Never store** secrets, tokens, credentials, or private personal data.

Store only when the record:

- changes a future decision,
- captures a blocker, assumption, or dependency,
- records a non-obvious project convention, or
- lets a later session restart without repeating discovery.

Skip raw command output, redundant status, and temporary reasoning.

## Record shape

- `key`: stable and specific: `task:auth-refactor`, `decision:path-layout`, `blocker:api-migration:missing-scope`.
- `contextType`: `workflow` · `decision` · `blocker` · `convention` · `handoff` · `interaction`.
- `value`: three lines: `Situation:` / `Decision:` / `Next:`.
- `metadataJson` (optional): owner, due date, links, confidence.

Stable patterns (naming, commit style, test commands) go in **conventions**, not per-session context.

```json
{
  "action": "store_context",
  "contextType": "blocker",
  "key": "api:migration:blocker:missing-scope",
  "value": "Situation: OAuth scope missing for write endpoint.\nDecision: pause write-tool rollout.\nNext: request scope update and re-test.",
  "metadataJson": "{\"owner\":\"platform\",\"priority\":\"high\"}"
}
```

## IDs

- `project_id` = git repo basename (`dotfiles`).
- `session_id` = repo basename for project work; `personal-assistant` for conversational sessions.
- `assemble_active_context` searches across all harnesses regardless of `session_id`.

## Session flow

**Start** (silently, no announcements):

1. Load preferences and project conventions.
2. List open tasks and blockers.
3. Retrieve specific keys only when prior context points to them; use `assemble_active_context` when continuity is unclear.
4. Fall back to `durable_memory` / `~/.agents/memory/` files only if the above has nothing for this project.

**During**: re-query only when context changes or uncertainty rises. Narrow queries over broad dumps. Track user corrections and new conventions silently.

**Handoff**: write one `handoff` record pointing at key context keys and file paths; keep `projects/<project>/current.md` aligned. Full workflow: `handoff-resume`.

## Core tools (keep the surface small)

The server exposes 60+ actions. Normal sessions need only:

| Tool                                                 | Purpose                                   |
| ---------------------------------------------------- | ----------------------------------------- |
| `store_session_context` / `update_session_context`   | Write or append a record                  |
| `retrieve_session_context`                           | Read by key or type                       |
| `assemble_active_context`                            | Pull active context to resume             |
| `track_user_preference` / `get_user_preferences`     | Style and workflow preferences            |
| `learn_project_convention` / `get_project_conventions` | Stable project patterns                 |
| `create_task` / `get_tasks` / `update_task`          | Task lifecycle                            |
| `search_memories`                                    | Full-text search                          |
| `server_health`                                      | Availability check                        |

Skip API-spec, analytics, routing-pattern, batch, and dashboard tools at runtime; they are maintenance surfaces.

## CLI (hooks, scripts, debugging, no-MCP harnesses)

```bash
# SQLite store (Claude Code's primary; bundled helper)
scripts/smem.sh sessions | list [sid] | get <key> [sid] | search <q> [sid]
scripts/smem.sh set <type> <key> <value> [sid]
scripts/smem.sh tasks [workflow_id] | prefs | conventions [project_id] | dump [sid]
SESSION_DB=/path/to/session.db scripts/smem.sh list   # override DB path
# Without [sid], smem.sh uses $SMEM_SESSION or "default", not the repo basename.
# Pass the sid explicitly, or: export SMEM_SESSION="$(basename "$(git rev-parse --show-toplevel)")"

# LeanCTX store (Pi's primary)
lean-ctx knowledge export --format json
lean-ctx task list          # requires `lean-ctx serve`
lean-ctx session status
```

Last resort: `sqlite3 ~/.agents/memory/session.db` (read-only queries).

## Durable files

```text
~/.agents/memory/projects/<project>/  # project state; artifacts/*-latest.md read first
~/.agents/memory/promoted/            # promoted exports, *-compact.md
~/.agents/memory/handoffs/YYYY/MM/    # handoff packets
~/.agents/memory/profile/             # identity and preferences
~/.agents/memory/people/              # local-only people context
```

Promotion is explicit, never automatic: `scripts/promote-session-memory.sh --session-id <id> --dry-run` to preview, then rerun without `--dry-run`.

## Verify after writing

1. Read the key back; confirm Situation/Decision/Next.
2. If task-tracked, confirm the task exists with the right state.
3. For promotions, confirm the file landed under `~/.agents/memory/`.

## Hygiene

- Merge overlapping records instead of adding near-duplicate keys.
- Prune records that no longer inform decisions.
- Each record should be scannable in five seconds.

More: `examples/memory-record-patterns.md`, `reference/storage-decision-matrix.md`.
