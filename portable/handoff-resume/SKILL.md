---
name: handoff-resume
description: Use when resuming interrupted work across sessions, handing off to another agent or teammate, or creating a restart-ready status snapshot.
version: 0.2.0
portable: true
tags: [workflow, continuity, handoff, resume]
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

1. Pull durable context — auto-injected on first turn from `durable_memory`; read and apply it.
2. Check task state: `workflow_tasks action=list` for current session tasks.
3. Check session memory: `session_memory action=retrieve_context` for recent decisions and blockers.
4. Validate stale assumptions before implementing (drift between memory and repo state).
5. Build status snapshot (see template below).
6. Execute next concrete step; record outcomes for future resume.

## Handoff workflow

At session end or before transfer:
1. Write a summary record: `session_memory action=store_context` with type `handoff`.
2. Run autodream: `durable_memory action=autodream_apply` to promote session to durable artifacts.
3. Leave a handoff file at `~/.agents/memory/handoffs/YYYY/MM/` with the template below.

```bash
# Helper scripts (from ~/.dotfiles)
./hacks/autodream-memory.sh --session-id <id> --apply
./hacks/new-memory-handoff.sh --project <slug> --topic <topic>
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
