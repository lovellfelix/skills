---
name: lean-ctx
description: Use when reading files, running shell commands, searching code, or exploring directories — anywhere native equivalents waste context tokens.
metadata:
  version: 0.1.0
  portable: true
  tags: [lean-ctx, compression, context-efficiency, portable]
---

# lean-ctx

## Overview

LeanCTX is the canonical runtime guidance for token-efficient reads, search, session context, and workflow state across Pi, Claude Code, and OpenCode.

**Source of truth:** LeanCTX (`ctx_knowledge`, `ctx_session`, `ctx_task`, `ctx_workflow`) is the primary runtime memory layer. `llm-wiki` and `durable_memory` are export/archive or fallback surfaces, not the canonical write path.

## Use this skill for

- Reading files without dumping large buffers into context
- Searching code or directories efficiently
- Running shell commands with compressed output by default
- Resuming work with LeanCTX-backed context before broad rediscovery
- Shared cross-harness guidance where Pi, Claude Code, and OpenCode should behave the same way

## Core tool mapping

Use `ctx_*` tools instead of native equivalents.

**Cross-harness canonical names:** prefer `ctx_search` for search and `ctx_tree` for directory listing in portable skills and shared docs.

| Action | Canonical | Pi aliases / notes |
| --- | --- | --- |
| Read file | `ctx_read(path, mode)` | same |
| Shell cmd | `ctx_shell(command)` | same |
| Search code | `ctx_search(pattern, path)` | Pi also provides `ctx_grep(pattern, path)` |
| List dir | `ctx_tree(path, depth)` | Pi also provides `ctx_ls(path)` |
| Find files | `ctx_search` + glob/filter | Pi also provides `ctx_find(glob, path)` |
| Edit fallback | `ctx_edit(path, old, new)` | native edit tools preferred when available |

**Pi-only aliases:** `ctx_grep`, `ctx_ls`, and `ctx_find` are convenient in Pi but should not be presented as the canonical cross-harness names.

## Mode selection for `ctx_read`

| Goal | Mode | When |
| --- | --- | --- |
| Edit this file | `full` | Before any edit |
| Understand API only | `signatures` | Context-only, no edit planned |
| Large file overview | `map` | Large files where full read would be wasteful |
| Specific region | `lines:N-M` | Exact location is known |
| Re-read after edit | `diff` | Verify recent changes |
| Unsure | `auto` | Let LeanCTX choose |

Use `fresh=true` when cached output is stale.

## Default workflow

1. **Orient:** `ctx_overview(task)` or session status for unfamiliar work.
2. **Locate:** `ctx_search` for text/paths; use `ctx_knowledge(action="recall")` for prior findings.
3. **Read:** `ctx_read(path, mode)` with the smallest useful mode.
4. **Edit:** use native edit tools first; use `ctx_edit` only when needed.
5. **Verify:** `ctx_read(path, "diff")` plus `ctx_shell("test-or-check")`.
6. **Record:** store non-obvious findings in LeanCTX-backed memory.

## Session guidance

- **Start:** `ctx_session(action="status")` → `ctx_knowledge(action="wakeup")` → `ctx_compress` → begin work.
- **Resume:** use project facts / session context before falling back to exported wiki notes or raw durable artifacts.
- **End:** record durable decisions in LeanCTX first; export to `llm-wiki` only when a human-readable archive is useful.

## Proactive compression

- **After wakeup:** always call `ctx_compress` before beginning work
- **Phase boundaries** (orient → implement, implement → verify): call `ctx_compress`
- **After 5+ ctx_read/ctx_search calls** in a phase: call `ctx_compress`
- **Wakeup scope:** cap at 20 items if `--limit` is supported; prefer category-scoped recalls over full dumps

## Compression bypass

When compressed output hides needed detail:

1. `ctx_read(path, "lines:N-M")`
2. `ctx_read(path, "full")`
3. `ctx_shell(command, raw=true)`

Return to compressed defaults after the expanded read.

## Risk gate

Before editing exported symbols, auth, DB schemas, or 3+ files, run impact-oriented discovery first:

- `ctx_impact(action="analyze")`
- `ctx_callgraph(action="callers")` when caller/callee context matters

## Advanced tools

Use directly when the harness exposes them:

- `ctx_overview(task)` — task-relevant project map
- `ctx_knowledge(action)` — cross-session facts and corrections
- `ctx_session(action)` — session state and persistence
- `ctx_graph(action)` — relationships and impact
- `ctx_impact(action)` — blast-radius analysis
- `ctx_callgraph(action)` — caller/callee analysis
- `lean_ctx` — direct CLI access for setup, overview, knowledge, session, graph, and pack commands

## Common mistakes

- Using native read/search/list tools when `ctx_*` equivalents are available
- Using Pi-only aliases in cross-harness docs instead of `ctx_search` / `ctx_tree`
- Reading full large files when `map`, `signatures`, or `lines:N-M` is enough
- Forgetting to verify with `diff` or a command-level check after edits
- Treating `llm-wiki` or `durable_memory` as the runtime source of truth

## Harness notes

| Harness | Provider | Init command |
| --- | --- | --- |
| Pi | `pi-lean-ctx` package + MCP | `lean-ctx init --agent pi` |
| Claude Code | MCP server + hooks | `lean-ctx init --agent claude` |
| OpenCode | MCP server + plugin | `lean-ctx init --agent opencode` |

For harness/bootstrap setup, symlink materialization, and re-init behavior, see `LEAN-CTX.md`.
