---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
version: 0.1.0
portable: true
tags: [planning, workflow, portable]
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

Adjust the path to match the project's conventions if `docs/plans/` does not already exist.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** When implementing this plan, work task-by-task with a fresh subagent per task and code review between tasks.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```
````

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

```text

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:"**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open a new session to execute the saved plan with batch execution and checkpoints

**If Subagent-Driven chosen:**
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- New session: implement tasks sequentially with validation checkpoints
```

---

# Actionable Planning (CLEAR framework)

This skillset from `actionable-planning` is merged here. Use when you need concrete, executable plans with clear ownership and success criteria.

## The CLEAR Framework

Every action item should be:

- C: Concrete — specific and measurable (bad: "Improve performance"; good: "Reduce API latency from 800ms to 200ms")
- L: Linked — dependencies explicit (e.g., "Depends on: Task A")
- E: Estimated — time/cost quantified (e.g., "4 hours, $50 API credits")
- A: Assigned — clear owner (e.g., "Owner: @john")
- R: Resulted — success criteria defined (e.g., "Done when: Tests pass, PR merged")

## Planning Best Practices

1. Start with the End in Mind
- Define success criteria FIRST
- Work backwards from deadline
- Identify the critical path

2. Break Down Ruthlessly
- Maximum 4-hour tasks (8 hours absolute max)
- If you can't estimate, break it down more
- Each task produces a tangible output

3. Make Dependencies Explicit
- Express dependencies (depends_on / blocked_by / blocks) in task metadata

4. Front-Load Risk
- Tackle unknowns early
- Build proofs-of-concept before committing

5. Create Parallel Batches
- Identify independent work streams to maximize parallelization

## Action Item & Plan Templates

Use the included Action Item Template and Plan Structure from the original `actionable-planning` skill. Keep tasks small, owned, and measurable.

## Output Checklist

Before finalizing a plan, verify:

- [ ] Every task has an owner
- [ ] Every task has an estimate
- [ ] Every task has success criteria (done when...)
- [ ] Dependencies are explicit and form a valid DAG (no cycles)
- [ ] Critical path is identified
- [ ] Risks have mitigations
- [ ] First 3 actions are immediately executable
- [ ] Total estimate fits within timeline (with buffer)
