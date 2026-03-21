---
name: session-memory-mcp
description: Practical patterns for storing, retrieving, and maintaining high-signal session memory via MCP.
version: 0.1.0
portable: true
tags: [mcp, memory, workflow, continuity, portable]
---

# Session Memory MCP

Use session-memory MCP as a durable context layer so sessions can resume quickly without drowning in noise.

## Use when

- You need cross-session continuity for active engineering work.
- You want to persist decisions, blockers, and next actions.
- A workflow has many steps and context can drift over time.
- You are coordinating multiple agents or handoffs.

## Do not use when

- Data is transient and has no value after the current response.
- Information is sensitive and should not be stored in memory.
- You are about to store duplicated low-signal logs or raw command spam.

## Inputs expected

- Session identifier and project identifier (if available).
- Current task state and meaningful decision points.
- Minimal metadata needed for retrieval (topic, phase, status).

## Workflow

1. Decide if information is worth storing.
2. Store concise, structured memory records.
3. Retrieve targeted context at session start and before major actions.
4. Sync todos and task status as work progresses.
5. Periodically prune stale/noisy records.

Durable memory convention for this skill:

- Session DB is the working layer (`~/.agents/memory/session.db`).
- Durable project state belongs in `~/.agents/memory/projects/<project>/`.
- Durable transfer packets belong in `~/.agents/memory/handoffs/YYYY/MM/`.
- Promoted exports belong in `~/.agents/memory/promoted/`.
- Durable identity/preferences belong in `~/.agents/memory/profile/`.
- Durable local-only people memory belongs in `~/.agents/memory/people/{profiles,notes,links}/`.
- `people/links/` stores local graph-oriented references to session-memory entities (meetings, projects, tasks, events).

## Core patterns

### 1) Store-or-skip filter

Store context only when at least one is true:

- It changes future decisions.
- It captures a blocker, assumption, or dependency.
- It records non-obvious project conventions.
- It enables restart without repeating discovery.

Skip storing when it is:

- Pure command output with no interpretation.
- Redundant status messages.
- Temporary thought process with no lasting value.

### 2) Context record structure

Prefer small records with predictable keys:

- `context_key`: stable lookup key (`task:auth-refactor`, `handoff:2026-03-20`).
- Use project-scoped keys when possible (`project:dotfiles:current`, `project:dotfiles:decision:path-layout`).
- Use durable people keys for first-class person context (`people:profile:<slug>`, `people:notes:<slug>`, `people:links:<slug>`).
- `context_type`: category (`workflow`, `decision`, `blocker`, `convention`, `handoff`).
- Add explicit person context types where needed (`people_profile`, `people_note_bundle`, `people_link_bundle`).
- `context_value`: concise, actionable text.
- `metadata`: optional JSON-like fields (owner, due date, links, confidence).

Good `context_value` pattern:

- Situation: what changed.
- Decision: chosen path and why.
- Next: immediate action.

### 3) Project convention storage

Store conventions separately from per-session updates.

- Use convention records for stable patterns (naming, commit style, test commands).
- Keep session context focused on current execution state.
- Link recurring patterns to project-level convention keys.

### 4) Todo sync and task hygiene

- Sync todos when task state changes, not every message.
- Keep todo items atomic and execution-oriented.
- Mark complete promptly to avoid stale boards.
- If a task is blocked, store blocker plus owner and unblock criteria.

### 5) Retrieval strategy

At session start:

1. Retrieve recent workflow contexts.
2. Retrieve open blockers and in-progress todos.
3. Retrieve project conventions relevant to current task.

During execution:

- Re-query memory only when context changed or uncertainty increased.
- Prefer narrow queries over broad dumps.

At handoff:

- Write one summary record that references key context keys plus durable file paths.
- Ensure `projects/<project>/current.md` and the new `handoffs/YYYY/MM/...md` packet stay aligned.

### 6) Noise control

- Merge overlapping notes into one updated record.
- Avoid repeated near-duplicate keys.
- Archive or prune stale records that no longer inform decisions.
- Keep records short enough to scan quickly.

## Cross-session sharing pattern

Use a two-layer approach:

1. Session layer: execution timeline for current work.
2. Project layer: stable conventions and reusable knowledge.

For handoffs between agents:

- Store a `handoff:*` record with blockers, next steps, and validation status.
- Include metadata pointing to durable files under `projects/` and `handoffs/`.
- Pair with `handoff-resume` to produce restart-ready summaries.

## Runtime notes (optional)

Runtime tool names vary, but the pattern is consistent:

- `store_*` operations for writing contexts/conventions.
- `retrieve_*` or `query_*` operations for targeted reads.
- `sync_todos` operations for task state continuity.

Adapt names to your MCP runtime while preserving this structure.

## Examples and reference

- `examples/memory-record-patterns.md`
- `reference/storage-decision-matrix.md`
