# Handoff Note Template

Use this at the end of a session to make resume easy in the next one.

```markdown
## Handoff

Goal:
- Ship session-memory retrieval for active branch context.

Completed this session:
- Added retrieval query for recent task state.
- Added validation checks for missing project context.

Current state:
- Resume summary rendering is implemented.
- Handoff persistence is pending.

Blockers:
- Need API token for production environment checks (owner: platform).

Next steps:
1. Add write path for handoff packet.
2. Run validation command and fix failures.
3. Update docs with example resume flow.

Validation:
- Ran: unit tests for resume summary.
- Not run: integration suite (blocked by token).

Resume command:
- make test-resume
```
