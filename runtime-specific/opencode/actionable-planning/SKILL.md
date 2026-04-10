---
name: actionable-planning
description: Create actionable plans using the CLEAR framework (Concrete, Linked, Estimated, Assigned, Resulted). Use when planning features, projects, or multi-step tasks requiring clear ownership and success criteria.
version: 0.1.0
portable: false
tags: [planning, execution, productivity, workflow, opencode]
applies_to: [planner, task-manager, orchestrator, personal-assistant]
---

# Actionable Planning Skill

Transform vague goals into **concrete, executable plans** using the CLEAR framework.

## The CLEAR Framework

Every action item must be:

| Letter | Principle | Bad Example | Good Example |
|--------|-----------|-------------|--------------|
| **C** | **Concrete** - Specific, measurable | "Improve performance" | "Reduce API latency from 800ms to 200ms" |
| **L** | **Linked** - Dependencies explicit | "Then do the next thing" | "Depends on: API schema (Task A)" |
| **E** | **Estimated** - Time/cost quantified | "This will take a while" | "4 hours, $50 API credits" |
| **A** | **Assigned** - Clear ownership | "Someone should..." | "Owner: @john" |
| **R** | **Resulted** - Success criteria defined | "When it's done" | "Done when: Tests pass, PR merged" |

## Planning Best Practices

### 1. Start with the End in Mind
- Define success criteria FIRST
- Work backwards from deadline
- Identify the critical path

### 2. Break Down Ruthlessly
- Maximum 4-hour tasks (8 hours absolute max)
- If you can't estimate, break it down more
- Each task produces a tangible output

### 3. Make Dependencies Explicit
```
Task B: "Implement API endpoints"
  └─ depends_on: Task A ("Define API schema")
  └─ blocked_by: None
  └─ blocks: Task C ("Build frontend")
```

### 4. Front-Load Risk
- Tackle unknowns early
- Build proof-of-concepts before committing
- Have contingency plans for high-risk items

### 5. Create Parallel Batches
- Identify independent work streams
- Maximize parallelization
- Minimize critical path length

## Action Item Template

Every task should follow this structure:

```markdown
### Task: [Verb] + [Object] + [Context]

**ID**: PROJ-001
**Owner**: @username
**Estimate**: 4 hours
**Priority**: P1 (Critical) / P2 (High) / P3 (Medium) / P4 (Low)
**Status**: Not Started / In Progress / Blocked / Done

**Dependencies**:
- Depends on: [Task IDs or "None"]
- Blocks: [Task IDs or "None"]

**Success Criteria**:
- [ ] [Specific, verifiable outcome 1]
- [ ] [Specific, verifiable outcome 2]

**Notes**: [Context, approach, considerations]
```

## Plan Structure Template

```markdown
# Plan: [Project/Goal Name]

## Overview
**Goal**: [One sentence describing desired outcome]
**Timeline**: [Start] → [End] ([Duration])
**Owner**: [Primary responsible person]
**Stakeholders**: [Who needs to be informed/consulted]

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

## Constraints
- **Time**: [Deadline, time budget]
- **Budget**: [Financial constraints]
- **Resources**: [People, tools, dependencies]
- **Scope**: [What's explicitly OUT of scope]

## Risk Assessment
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Plan B] |

## Phases

### Phase 1: [Name] ([Date Range])
**Goal**: [Phase objective]
**Exit Criteria**: [What must be true to move to Phase 2]

| ID | Task | Owner | Est. | Priority | Depends | Done When |
|----|------|-------|------|----------|---------|-----------|
| 1.1 | [Action verb + object] | @name | 2h | P1 | - | [Criteria] |
| 1.2 | [Action verb + object] | @name | 4h | P1 | 1.1 | [Criteria] |

### Phase 2: [Name] ([Date Range])
...

## Parallel Execution Map
```
Week 1:  [──Task A──]  [──Task B──]
         [────Task C────]
Week 2:              [──Task D──]  (depends on A)
                     [──Task E──]  (depends on B)
```

## Communication Plan
- **Daily**: [Stand-up / async update]
- **Weekly**: [Review meeting]
- **Milestone**: [Demo / stakeholder update]

## Next Steps
1. [Immediate action #1] - [Owner] - [By when]
2. [Immediate action #2] - [Owner] - [By when]
```

## Breaking Down Large Tasks

### The "Can You Demo It?" Test
If you can't demo the result of a task, it's too vague. Break it down.

❌ "Work on authentication" - Can't demo "working on" something
✅ "Create login form with email/password fields" - Can demo the form

### Size Guidelines

| Estimate | Action |
|----------|--------|
| < 30 min | Good - atomic task |
| 30 min - 4 hrs | Good - manageable chunk |
| 4 - 8 hrs | Acceptable - consider splitting |
| 8+ hrs | Too large - must split |
| "A few days" | Way too large - break into phases |

### Decomposition Patterns

**Feature → Components → Tasks**
```
Feature: User Authentication
├── Component: Login
│   ├── Task: Create login form UI
│   ├── Task: Implement form validation
│   └── Task: Connect to auth API
├── Component: Registration
│   ├── Task: Create registration form UI
│   └── Task: Implement email verification
└── Component: Password Reset
    ├── Task: Create reset request form
    └── Task: Implement reset flow
```

**CRUD Pattern**
```
Feature: User Management
├── Create: Add new user endpoint + UI
├── Read: List users + user detail pages
├── Update: Edit user form + API
└── Delete: Delete confirmation + API
```

## Dependency Analysis

### Dependency Types

1. **Finish-to-Start (FS)** - Most common
   - Task B cannot start until Task A finishes
   - Example: "Can't deploy until tests pass"

2. **Start-to-Start (SS)**
   - Task B cannot start until Task A starts
   - Example: "QA can start once dev starts (parallel work)"

3. **Finish-to-Finish (FF)**
   - Task B cannot finish until Task A finishes
   - Example: "Documentation can't be finalized until feature is complete"

4. **Start-to-Finish (SF)** - Rare
   - Task B cannot finish until Task A starts
   - Example: "Old system runs until new system starts"

### Critical Path Identification

1. List all tasks with dependencies
2. Calculate earliest start/finish for each
3. Calculate latest start/finish for each
4. Critical path = tasks where earliest == latest (no slack)

```
Critical Path: A → C → E → G
              [2h] [4h] [3h] [2h] = 11 hours minimum

Non-critical: B (2h slack), D (4h slack), F (1h slack)
```

## Estimation Techniques

### Planning Poker (Team)
- Each person estimates independently
- Discuss outliers
- Converge on consensus

### PERT Estimation (Individual)
```
Estimate = (Optimistic + 4×Likely + Pessimistic) / 6

Example:
- Optimistic: 2 hours
- Likely: 4 hours  
- Pessimistic: 10 hours
- PERT: (2 + 16 + 10) / 6 = 4.7 hours
```

### Estimation Multipliers

| Situation | Multiply Base Estimate By |
|-----------|---------------------------|
| New technology | 1.5x - 2x |
| Unclear requirements | 1.5x |
| External dependencies | 1.3x |
| First time doing this | 2x |
| Integration work | 1.5x |

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

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| "Finish the feature" | Not actionable | Break into specific tasks |
| No estimates | Can't track progress | Add time estimates |
| Everything is P1 | Nothing is prioritized | Use MoSCoW or P1-P4 |
| Hidden dependencies | Blocked work | Make all deps explicit |
| No success criteria | Scope creep | Define "done" upfront |
| Single owner for everything | Bottleneck | Distribute ownership |
| No buffer | Inevitable delays | Add 20-30% contingency |
