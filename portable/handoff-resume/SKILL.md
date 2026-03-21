---
name: handoff-resume
description: Resume interrupted work and produce clean handoffs with clear blockers and next steps.
version: 0.1.0
portable: true
tags: [workflow, continuity, handoff, resume, portable]
---

# Handoff Resume

Resume work quickly from prior session state, then leave behind a crisp handoff for the next session or teammate.

## Use when

- User says "pick up where I left off", "what was I working on", or "resume this task".
- A task spans multiple sessions and current context may be stale.
- You need to transfer work between agents or between people.
- You are ending a session and want a reliable restart point.

## Do not use when

- The work is fully complete and no follow-up is needed.
- There is no retrievable context and the user has already provided fresh requirements.
- The user asks for only a small one-off answer with no continuity needs.

## Inputs expected

- Current objective (or best inferred objective from recent activity).
- Available traces: recent tasks, notes, commits, PRs, and memory snapshots.
- Current constraints: deadlines, blockers, approvals, dependencies.

## Workflow

1. Reconstruct latest state from the most trustworthy sources available.
2. Build a short status snapshot: last actions, current state, blockers, next steps.
3. Validate stale assumptions before continuing implementation.
4. Execute next concrete step, then record outcomes for future resume.
5. End with a handoff packet that another session can act on immediately.

## Core patterns

Durable memory convention for this skill:

- Project state lives at `~/.agents/memory/projects/<project>/`.
- Session handoff packets live at `~/.agents/memory/handoffs/YYYY/MM/`.
- Profile + people durable context live at `~/.agents/memory/{profile,people}/`.
- Keep handoff files append-only; write a new packet for each pause.

### 1) Resume snapshot (read path)

Create a compact resume snapshot in this order:

1. Current in-progress tasks and recently completed tasks.
2. Most recent session notes or memory records.
3. Durable project state from `projects/<project>/current.md` and `projects/<project>/decisions.md`.
4. Latest handoff packet from `handoffs/YYYY/MM/` for this project/topic.
5. Latest repo activity (branch, commits, diffs, open PR context).
6. Open dependencies and unresolved blockers.

Output structure:

- Objective: one sentence.
- Last actions: 2-5 bullets.
- Current state: done / in-progress / pending.
- Blockers: explicit owner or dependency.
- Next steps: numbered list with smallest executable actions.

### 2) Continuation guardrails

Before coding:

- Confirm whether blockers are still real.
- Detect drift between memory and current repo state.
- Prefer facts from source of truth over stale notes.
- Call out unknowns clearly instead of guessing.

### 3) Handoff packet (write path)

When pausing or transferring work, leave a handoff packet with:

- Goal and definition of done.
- What changed in this session.
- What is still pending.
- Known blockers and who can unblock.
- Exact next command or first action for restart.
- Validation status (what ran, what did not run).
- Durable references to `projects/<project>/` and `promoted/<timestamp>-<session>.{json,md}` if used.

Keep it scannable and executable in under 60 seconds.

Helper script:

```bash
./hacks/generate-memory-handoff-summary.sh --project <project-slug> --session-id <session-id> --summary-file <handoff.md>
```

## Handoff template

```markdown
## Handoff

Goal:
- <target outcome>

Completed this session:
- <change 1>
- <change 2>

Current state:
- <in-progress item>

Blockers:
- <blocker> (owner: <name>, unblock path: <action>)

Next steps:
1. <smallest next action>
2. <follow-up action>

Validation:
- Ran: <tests/checks>
- Not run: <tests/checks and why>

Resume command:
- <first command to run next session>

Durable memory references:
- Project state: ~/.agents/memory/projects/<project>/current.md
- Handoff file: ~/.agents/memory/handoffs/YYYY/MM/<timestamp>-<project>-<topic>.md
- Promoted snapshot: ~/.agents/memory/promoted/<timestamp>-<session>.md
```

## Quality bar

- Prefer specific file paths, IDs, and commands over vague prose.
- Keep narrative short; prioritize actionability.
- If confidence is low, mark assumptions and verification needed.
- Handoff must let a fresh agent start without re-discovery.

## Works well with

- `session-memory-mcp` for storing and retrieving session snapshots.
- Project task tracking for durable TODO and dependency state.

## Examples and reference

- `examples/handoff-note-template.md`
- `reference/resume-checklist.md`
