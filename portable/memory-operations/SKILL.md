---
name: memory-operations
description: Coordinate session-memory capture, durable promotion, and handoff-ready resume workflows.
version: 0.1.0
portable: true
tags: [memory, mcp, handoff, resume, durability]
---

# Memory Operations

> **Prerequisites (runtime-specific):** This skill requires the `~/.agents/memory/` directory
> structure and the `session-memory` MCP configured in OpenCode. It will not work portably
> on machines without this setup. See `session-memory-mcp` skill for the portable patterns.


Use this meta-skill to run a safe, repeatable memory workflow: collect high-signal session memory, promote durable artifacts, and leave a restart-ready handoff.

## Use when

- You are wrapping up a multi-step task and want durable memory artifacts.
- You need reliable resume context for the next session.
- A workflow needs both MCP session memory and human-readable handoff notes.

## Do not use when

- Work is trivial and no continuity is required.
- Data is sensitive and should not be persisted.

## Composed skills

- `session-memory-mcp` for high-signal storage and retrieval patterns.
- `handoff-resume` for restart-ready status snapshots and handoff packets.

## Workflow

1. Capture or refresh key session memory records using `session-memory-mcp` patterns.
2. Promote selected session context into durable files under `~/.agents/memory/promoted/`.
3. Keep durable identity/preferences in `~/.agents/memory/profile/` and local-only people context in `~/.agents/memory/people/`.
4. Update project-scoped state under `~/.agents/memory/projects/<project>/`.
5. Build a concise handoff packet under `~/.agents/memory/handoffs/YYYY/MM/` using `handoff-resume` structure.
6. Store a final `handoff:*` context record that points to promoted artifacts.

Canonical path conventions:

- Durable project memory: `~/.agents/memory/projects/<project>/`
- Durable handoff packets: `~/.agents/memory/handoffs/YYYY/MM/`
- Promoted exports: `~/.agents/memory/promoted/`
- Durable profile memory: `~/.agents/memory/profile/`
- Durable people memory: `~/.agents/memory/people/{profiles,notes,links}/`
- `people/links/` is for local graph-oriented references to session-memory entities (meetings, projects, tasks, events)
- Working cache only: `CLAUDE.md` (do not treat as durable source of truth)

## Durable promotion helper

Use the helper script from this repo:

```bash
./hacks/promote-session-memory.sh --session-id <session-id>
```

Optional flags:

- `--label <name>` to add a descriptive suffix to filenames.
- `--db <path>` to target a specific session-memory database.
- `--agents-home <path>` to test outside `~/.agents`.
- `--dry-run` to preview filesystem actions.

After promoting, update project + handoff durable files so MCP records and filesystem artifacts stay aligned.

Project and handoff helpers:

```bash
./hacks/init-memory-project.sh --project <project-slug>
./hacks/new-memory-handoff.sh --project <project-slug> --topic <topic>
./hacks/generate-memory-handoff-summary.sh --project <project-slug> --session-id <session-id> --summary "<short summary>"
./hacks/sync-memory-markdown-mcp.sh export --scope all
./hacks/sync-memory-markdown-mcp.sh import --scope all --overwrite
./hacks/manage-people-memory.sh delete --person <person-slug> --kind links
./hacks/manage-people-memory.sh redact --person <person-slug> --kind all --field "<text>"
```

## Safety rules

- Never replace `~/.agents/memory` wholesale.
- Only create missing files/directories inside canonical memory paths.
- Keep promoted artifacts append-only by timestamped filenames.
- Keep handoffs append-only by timestamped filenames.
- Treat `people/` memory as local-only durable storage; do not commit or share it.
- Review promoted content before sharing outside the machine.
