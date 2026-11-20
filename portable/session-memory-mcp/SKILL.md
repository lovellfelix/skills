---
name: session-memory-mcp
description: Use when preserving cross-session context, recording decisions, blockers, conventions or preferences, or writing a handoff. Durable memory is plain files in ~/.agents/memory; the session_memory MCP and its SQLite store are legacy and only used when explicitly present.
metadata:
  version: 0.6.0
  portable: true
  tags: [mcp, memory, workflow, continuity]
---

# Session Memory

A small durable context layer so sessions resume without re-discovery. Store decisions, not transcripts.

Related: `handoff-resume` (resume/handoff workflow), `llm-wiki-workflow` (human-readable archive).

## Status

The `session_memory` MCP server and its SQLite store (`~/.agents/memory/session.db`) are **legacy**: no harness registers them by default, and `session.db` is not written to any more. Durable memory is plain files:

| Harness     | Where memory lives                                                                 |
| ----------- | ---------------------------------------------------------------------------------- |
| Claude Code | Auto-memory directory (`~/.agents/memory/projects/<repo>/` when the repo sets it) + `global/` |
| Pi          | `agent_memory` tool over `~/.agents/memory`; `workflow_tasks` for tasks             |
| OpenCode, others | Read and write the same files directly                                        |

Check `claude mcp list` / the harness MCP config before assuming a `session_memory` tool exists. Without one, use the files below. Pending in-session work goes in the harness todo list or a plan file.

## Store or skip

**Never store** secrets, tokens, credentials, or private personal data.

Store only when the fact changes a future decision, captures a blocker or assumption, records a non-obvious convention, or lets a later session restart without repeating discovery. Skip raw command output, redundant status, and temporary reasoning.

## Where facts go

One fact per file, with `name` / `description` / `type` frontmatter, and one line per fact in the folder's `MEMORY.md` index. Save a fact in exactly one place:

```text
~/.agents/memory/global/            # applies in every repo (preferences, corrections)
~/.agents/memory/projects/<repo>/   # about one repo; project_id = git repo basename
~/.agents/memory/handoffs/YYYY/MM/  # handoff packets (see handoff-resume)
~/llm-wiki                          # long-form archive, promoted via llm-wiki-workflow
```

Facts are `user`, `feedback` (rule + **Why** + **How to apply**), `project`, or `reference`. Merge overlapping facts instead of adding near-duplicates; delete ones that turn out wrong.

## Legacy store (only if a `session.db` is present and you need old records)

```bash
scripts/smem.sh sessions | list [sid] | get <key> [sid] | search <q> [sid] | tasks | prefs | conventions
SESSION_DB=/path/to/session.db scripts/smem.sh list
scripts/promote-session-memory.sh --session-id <id> --dry-run   # promote old records to files
```

`smem.sh` needs `sqlite3`. Read old records, then re-save what is still true as files.

More: `examples/memory-record-patterns.md`, `reference/storage-decision-matrix.md`.
