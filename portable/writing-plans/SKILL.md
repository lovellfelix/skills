---
name: writing-plans
description: Use when you have a spec, requirements, or an agreed design for a multi-step task and need an implementation or action plan before touching code, or when a plan needs owners, estimates, dependencies, and success criteria.
metadata:
  version: 0.2.0
  portable: true
  tags: [planning, workflow, tdd, portable]
---

# Writing Plans

Write the plan for an engineer (or agent) who is skilled but has zero context on this codebase, its tools, or its domain, and weak test-design instincts. Give them everything: which files to touch, the code, the tests, the commands, the expected output. Bite-sized tasks. DRY, YAGNI, TDD, frequent commits.

If the design itself is still open, settle it first (`grill-with-docs`, or `rfc` for larger changes). A plan executes decisions; it doesn't make them.

**Save to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`, or the project's existing plans directory.

## Header

Every plan starts with:

```markdown
# <Feature Name> Implementation Plan

> **For the implementer:** work task by task; run the review step between tasks.

**Goal:** <one sentence>
**Architecture:** <2–3 sentences on the approach>
**Tech stack:** <key technologies and libraries>
**Done when:** <observable success criteria for the whole plan>
```

## Tasks

Each step is one 2–5 minute action. Write failing test, run it, implement, run again, and commit are five separate steps.

````markdown
### Task N: <component>

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test_file.py`

**Depends on:** Task M (or "none")

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    assert function(input) == expected
```

**Step 2: Run it and confirm it fails**

Run: `pytest tests/exact/path/to/test_file.py::test_specific_behavior -v`
Expected: FAIL with `NameError: function`

**Step 3: Minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run it and confirm it passes**

Run: same command. Expected: PASS

**Step 5: Commit**

`git add <files> && git commit -m "Add specific behavior"`
````

## Rules

- Exact file paths, always.
- Complete code in the plan, never "add validation here".
- Exact commands with expected output.
- Name relevant skills by name (e.g. "use `python` for test conventions"), don't paste them.
- Front-load risk: unknowns and proofs of concept go first.
- Mark independent tasks so they can run in parallel.

## Non-code and team plans (CLEAR)

When tasks have human owners or span days (migrations, launches, multi-team work), every action item must be:

- **Concrete**: measurable ("cut p95 API latency from 800ms to 200ms", not "improve performance").
- **Linked**: `depends_on` / `blocks` explicit; dependencies form a DAG.
- **Estimated**: ≤4h per task (8h hard max). Can't estimate it? Break it down.
- **Assigned**: one owner.
- **Resulted**: "done when…" stated.

```markdown
| # | Task | Owner | Est. | Depends on | Done when |
|---|------|-------|------|------------|-----------|
| 1 | Snapshot prod DB and verify restore | @ops | 2h | none | Restore tested on staging |
| 2 | Run migration on staging | @dev | 1h | 1 | Smoke tests green |
```

## Before handing off

- [ ] Every task has files, steps, and a verification command (or owner, estimate, and "done when" for CLEAR tasks)
- [ ] Dependencies explicit; critical path identified
- [ ] Risks have mitigations; risky tasks scheduled first
- [ ] First three steps are immediately executable
- [ ] Total estimate fits the timeline with buffer

## Execution handoff

After saving, offer:

1. **This session:** execute task by task, with a fresh subagent per task if the harness supports subagents, reviewing between tasks.
2. **Separate session:** open a new session (ideally in a git worktree) that executes the saved plan with checkpoints.
