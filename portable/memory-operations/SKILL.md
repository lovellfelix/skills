---
name: memory-operations
description: Coordinate session-memory capture, durable promotion, and handoff-ready resume workflows.
version: 0.2.0
portable: true
tags: [memory, mcp, handoff, resume, durability]
---

# Memory Operations

Meta-skill for running a safe, repeatable memory workflow: capture session memory, promote durable artifacts, leave a restart-ready handoff.

## Use when

- Wrapping up a multi-step task and want durable artifacts.
- Need reliable resume context for the next session.
- Workflow needs both live session memory and human-readable handoff notes.

## Do not use when

- Work is trivial with no continuity needed.
- Data is sensitive and must not be persisted.

## Composed with

- `session-memory-mcp` — live storage and retrieval patterns.
- `handoff-resume` — restart-ready status snapshots and handoff packets.

## Workflow

1. Store high-signal session context via `session_memory` tool.
2. Track task progress via `workflow_tasks` (session-scoped, resets each new Pi session).
3. Promote selected context to durable disk artifacts via `durable_memory action=autodream_apply`.
4. Update project-scoped state under `~/.agents/memory/projects/<project>/`.
5. Write handoff packet under `~/.agents/memory/handoffs/YYYY/MM/` using `handoff-resume` template.
6. Store a final `handoff:*` context record that points to promoted artifacts.

## Path conventions

```
~/.agents/memory/session.db              # live session layer
~/.agents/memory/projects/<project>/     # project-scoped durable state
~/.agents/memory/handoffs/YYYY/MM/       # handoff packets (append-only)
~/.agents/memory/promoted/               # autodream-promoted exports
~/.agents/memory/profile/                # identity and preferences
~/.agents/memory/people/                 # local-only people context
```

## Helper scripts

```bash
# Promote session to durable artifacts
./hacks/autodream-memory.sh --session-id <id> --apply

# Bootstrap project memory directory
./hacks/init-memory-project.sh --project <project-slug>

# Write a new handoff packet
./hacks/new-memory-handoff.sh --project <project-slug> --topic <topic>

# Sync markdown ↔ MCP (export/import)
./hacks/sync-memory-markdown-mcp.sh export --scope all
./hacks/sync-memory-markdown-mcp.sh import --scope all --overwrite
```

## Safety rules

- Never replace `~/.agents/memory` wholesale.
- Promoted and handoff artifacts are append-only by timestamped filename.
- People memory is local-only — do not commit or share.
- Review promoted content before sharing outside the machine.
