---
name: lean-ctx
description: Use when reading files, running shell commands, searching code, or exploring directories — anywhere native equivalents waste context tokens.
metadata:
  version: 0.1.0
  portable: true
  tags: [lean-ctx, compression, context-efficiency, portable]
---

# lean-ctx — Context Runtime for AI Agents

## Overview

lean-ctx is a context runtime that compresses tool output by 60–90%, saving tokens on every read, shell command, grep, and directory listing. It provides `ctx_*` tools alongside or replacing native equivalents across Pi, Claude Code, and OpenCode.

## Setup

```bash
which lean-ctx || bash scripts/install.sh
lean-ctx setup
```

Or install directly: `curl -fsSL https://raw.githubusercontent.com/yvgude/lean-ctx/main/skills/lean-ctx/scripts/install.sh | bash`

Verify: run `/mcp` (Pi) or check `ctx_read` is available in your tool list.

## Core Tool Mapping

Use `ctx_*` tools instead of native equivalents. Choose the column that matches your harness:

| Action | Pi | Claude Code / OpenCode |
|--------|----|------------------------|
| Read file | `ctx_read(path, mode)` | `ctx_read(path, mode)` |
| Shell command | `ctx_shell(command)` | `ctx_shell(command)` |
| Search code | `ctx_grep(pattern, path)` | `ctx_search(pattern, path)` |
| List directory | `ctx_ls(path)` | `ctx_tree(path, depth)` |
| Find files | `ctx_find(glob, path)` | `ctx_search` + glob |
| Edit (fallback) | `ctx_edit(path, old, new)` | `ctx_edit(path, old, new)` |

> **Portability:** Pi also has `ctx_search`/`ctx_tree` via `directTools`. For cross-harness skills, prefer `ctx_search`/`ctx_tree` so the same instructions work on Claude Code and OpenCode.

Native Edit/StrReplace work on all harnesses. Only use `ctx_edit` when those are unavailable.

## ctx_read Mode Selection

| Goal | Mode | When |
|------|------|------|
| Edit this file | `full` | Before any edit |
| Understand API | `signatures` | Context-only, won't edit |
| Re-read after edit | `diff` | Post-edit verification |
| Large file overview | `map` | >500 lines, won't edit |
| Specific region | `lines:N-M` | Know exact line range |
| Unsure | `auto` | System selects optimal mode |

Re-reads cost ~13 tokens. Add `fresh=true` to bypass cache.

## Workflow

1. **Orient:** `ctx_overview(task)` or session status for unfamiliar tasks
2. **Locate:** `ctx_search`/`ctx_grep` for exact text; `ctx_knowledge(action="recall")` for prior findings
3. **Read:** `ctx_read(path, mode)` with appropriate mode
4. **Edit:** native Edit/StrReplace, or `ctx_edit` as fallback
5. **Verify:** `ctx_read(path, "diff")` + `ctx_shell("test command")`
6. **Record:** `ctx_knowledge(action="remember", ...)` for non-obvious findings

## Proactive (use without being asked)

- `ctx_overview(task)` — at session start for orientation
- `ctx_knowledge(action="wakeup")` — at session start to surface prior findings
- `ctx_compress` — when context grows large (at phase boundaries)

## Compression Bypass

When compressed output hides needed detail:
`ctx_read(path, "lines:N-M")` → `ctx_read(path, "full")` → `ctx_shell(cmd, raw=true)`

Return to compressed defaults after one expanded retrieval.

## Risk Gate

Before editing exported symbols, auth, DB schemas, or 3+ files: run `ctx_impact(action="analyze")` to confirm blast radius.

## Session

- **Start:** `ctx_session(action="status")` + `ctx_knowledge(action="wakeup")`
- **End:** `ctx_session(action="decision", content="what was done + next steps")`

## Advanced Tools

Available via `ctx_call(name, args)` or direct tool call:

- `ctx_overview(task)` — task-relevant project map
- `ctx_knowledge(action)` — project knowledge across sessions
- `ctx_session(action)` — session state and persistence
- `ctx_graph(action)` — code relationships and impact
- `ctx_impact(action)` — blast radius analysis
- `ctx_callgraph(action)` — caller/callee analysis
- `lean_ctx` — direct CLI access (e.g. `lean_ctx overview`, `lean_ctx gain`)

## Task Integration

Pi's `workflow_tasks` tool uses `ctx_knowledge` facts for task state tracking. Each task is stored as a pipe-delimited fact in the `task` category with a compound key.

### Fact Format

```
[task/wf:{workflowId}:{taskId}]: {title}|{state}|{priority}|{description}|{agent}
```

- **workflowId** — session-scoped identifier (derived from Pi session UUID)
- **taskId** — unique task key (format: `{workflowId}-{timestamp36}`)
- **state** — one of: `queued`, `in_progress`, `done`, `failed`, `blocked`
- **priority** — integer (lower = higher priority)
- **description** — optional task detail
- **agent** — delegated agent name (if any)

### Retrieval

Tasks are recalled via `lean-ctx knowledge recall "" --category task --mode exact` and parsed by the `parseFactLine` helper in `shared/leanctx.ts`. The `workflow_tasks` Pi tool (extension at `pi/.pi/agent/extensions/workflow-task-state/index.ts`) provides create/start/complete/block/fail/clear_done/list actions.

### State Mapping

| Pi workflow_tasks state | LeanCTX fact state |
|-------------------------|-------------------|
| `queued` | `queued` |
| `in_progress` | `in_progress` |
| `done` | `done` |
| `failed` | `failed` |
| `blocked` | `blocked` |

### Advanced: ctx_task / ctx_workflow (HTTP API)

The `session_memory` tool's `task_board` and `task_insights` actions bridge to LeanCTX's `ctx_task` and `ctx_workflow` HTTP tools (via `lean-ctx serve`). These are available for advanced multi-agent workflows and carry a stricter state enum (`working`, `input-required`, `completed`, `failed`, `canceled`). The shared `leanctx.ts` module provides `mapPiStateToLeanCtx` / `mapLeanCtxStateToPi` helpers for state translation.

### Practical Example

```bash
# List task facts via lean-ctx CLI
lean-ctx knowledge recall "" --category task --mode exact

# Example fact (stored by workflow_tasks):
# [task/wf:sess-abc123:abc123-m0a1b2]: Fix login timeout|in_progress|0|Set 10s deadline|worker

# Check knowledge health
lean-ctx knowledge status
```

## Common Mistakes

- **Not using compression bypass** — when a full file or raw command output is needed, expand with `full`/`raw=true` then return to compressed defaults
- **Skipping orient step** — `ctx_overview` before editing unfamiliar code saves multiple round-trips
- **Forgetting session end** — `ctx_session(action="decision")` preserves context for the next session
- **Using harness-specific tools in cross-harness skills** — prefer `ctx_search`/`ctx_tree` for portability

## Harness Notes

| Harness | Tool provider | Init command |
|---------|---------------|-------------|
| Pi | `pi-lean-ctx` npm package + MCP | `lean-ctx init --agent pi` |
| Claude Code | MCP server + shell hooks | `lean-ctx init --agent claude` |
| OpenCode | MCP server + plugin | `lean-ctx init --agent opencode` |
