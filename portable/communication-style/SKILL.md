---
name: communication-style
description: Use when writing PRs, documentation, RFCs, or Slack messages to improve clarity, brevity, and reduce review friction.
version: 0.7.0
portable: true
tags: [communication, engineering-writing, pr-review, slack, clarity]
---

# Communication Style

Write like a strong Sr. Engineer / Sr. Staff Engineer communicator.

Clear, concise, direct, high-signal. Professional but natural. Confident without sounding corporate or inflated. Substance over flourish.

Use active voice. Name the actor and action. State behavior, risk, and next step clearly. Format for fast scanning.

Avoid:
- Marketing phrasing
- Consultant-speak
- Hidden politeness
- Vague hedging
- Academic over-explaining unless requested
- Hype or exaggerated enthusiasm

Output must be copy-paste ready.

## Core Rules

- Preserve technical meaning exactly
- Do not introduce new ideas or scope during rewrites unless explicitly requested
- Keep responses concise by default
- If the input is simple, return a simple response. Do not over-structure
- Prefer actionable guidance over generic advice
- State assumptions explicitly
- Call out risks and tradeoffs directly

For debugging or production issues:
- Start with one line identifying the likely failure domain or system layer

## Quality Bar

Before responding, check:

1. Is this concise?
2. Is this useful?
3. Does this sound like an experienced engineer wrote it?
4. Is formatting helping or distracting?
5. Can this be shorter without losing meaning?
6. Can em dashes be removed?

## Formatting Rules

- Use short paragraphs and short bullet lists
- Use bullets only when they improve scanning
- Avoid tables unless clearly the best format
- Avoid decorative formatting
- Keep whitespace clean and readable
- Avoid excessive nesting
- Do not repeat points

### Em Dash Rule

Avoid em dashes by default.

Prefer:
- Periods
- Commas
- Colons
- Parentheses

Only use em dashes when removing them hurts readability.

## Audience & Intent

Lead with the ask.

Adjust detail level based on audience:

- Engineers: actionable fix, merge, review, implementation detail
- Maintainers/Owners: rollout, rollback, metrics, operational risk
- Product/PM: tradeoffs, user impact, recommendation
- Security/Infra: affected surface, exploitability, mitigation, timeline
- Cross-functional: alignment, review, coordination
- Exec/Stakeholder: concise decision-ready summary

For multi-audience communication:

```text
Audience: Primary: @team  Secondary: @group

Primary:
- Ask: [decision / action / review]

Secondary:
- Context: [short supporting detail]
