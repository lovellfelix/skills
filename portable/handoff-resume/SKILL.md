---
name: handoff-resume
description: Use when resuming interrupted work across sessions, handing off to another agent or teammate, or creating a restart-ready status snapshot.
metadata:
  version: 0.2.1
  portable: true
  tags: [workflow, continuity, handoff, resume, portable]
---

# Handoff Resume

Resume work quickly from prior session state, then leave a crisp handoff for the next session or teammate.

## Use when

- User says "pick up where I left off", "what was I working on", or "resume".
- A task spans multiple sessions and current context may be stale.
- Transferring work between agents or people.
- Ending a session and want a reliable restart point.

## Do not use when

- Work is complete with no follow-up needed.
- No retrievable context and the user provides fresh requirements.
- User asks for a small one-off answer with no continuity needs.

## Resume workflow

1. Pull session memory first (backend depends on the harness; see `session-memory-mcp`). Use `durable_memory` / `~/.agents/memory/` files only as a fallback for handoffs not yet in the store.
2. Check task state: `get_tasks` (Claude Code) or `workflow_tasks action=list` (Pi/LeanCTX).
3. Retrieve recent decisions and blockers: `assemble_active_context`, or `retrieve_context` for known keys.
4. Validate stale assumptions before implementing (drift between memory and repo state).
5. Build status snapshot (see template below).
6. Execute next concrete step; record outcomes for future resume.

## Handoff workflow

At session end or before transfer:

1. Write a summary record with type `handoff` via session memory. Where LeanCTX `ctx_handoff` is available, prefer it for structured handoff artifacts.
2. Promote the session to durable artifacts: `./scripts/autodream-memory.sh --session-id <id>` to preview, then add `--apply`.
3. Leave a handoff file at `~/.agents/memory/handoffs/YYYY/MM/` using the template below (`./scripts/new-memory-handoff.sh` scaffolds it).

```bash
# Helper scripts (bundled with this skill)
./scripts/autodream-memory.sh --session-id <id> --apply
./scripts/new-memory-handoff.sh --project <slug> --topic <topic>
```

## Status snapshot template

```text
Objective: <one sentence>

Last actions:
- <change 1>
- <change 2>

Current state: <done / in-progress / blocked>

Blockers:
- <blocker> (owner: <name>, unblock: <action>)

Next steps:
1. <smallest next action>
2. <follow-up>

Validation:
- Ran: <tests/checks>
- Not run: <reason>

Resume:
- <first command or action next session>

Refs:
- Project: ~/.agents/memory/projects/<project>/current.md
- Handoff: ~/.agents/memory/handoffs/YYYY/MM/<timestamp>-<project>.md
- Promoted: ~/.agents/memory/promoted/<timestamp>-<session>-compact.md
```

## Quality bar

- Specific file paths, IDs, commands — not vague prose.
- Keep narrative short; prioritize actionability.
- Mark low-confidence assumptions explicitly.
- Handoff must let a fresh agent start without re-discovery.
