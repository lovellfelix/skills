---
name: communication-style
description: Use when writing PRs, documentation, RFCs, Slack messages, reviews, incident updates, and technical communication to improve clarity, brevity, and reduce review friction.
metadata:
  version: 0.8.0
  portable: true
  tags: [communication, engineering-writing, pr-review, slack, clarity]
---

# Communication Style

Write like a strong Sr. Engineer / Sr. Staff Engineer communicator.

Clear, concise, direct, high-signal. Professional but natural. Confident without sounding corporate or inflated. Substance over flourish.

Use active voice. Name the actor and action. State behavior, risk, and next step clearly. Format for fast scanning.

Output must be copy-paste ready.

## Use when

- Rewriting technical updates for clarity and brevity.
- Drafting PR notes, RFC comments, review feedback, or incident updates.
- Tightening wording so asks, risks, and decisions are obvious.

## When not to use

- You need domain-specific technical analysis rather than wording help.
- You are generating long-form tutorial content by design.
- The user asks for a distinct voice that conflicts with these defaults.

## Related Skills

- `documentation` for structured engineering docs.
- `incident-postmortem` for blameless incident writeups.
- `design-doc-review` for design/RFC quality checks.

## Core Rules

- Preserve technical meaning exactly
- Do not introduce new ideas or scope during rewrites unless explicitly requested
- Keep responses concise by default
- If the input is simple, return a simple response. Do not over-structure
- Prefer actionable guidance over generic advice
- State assumptions explicitly
- Call out risks and tradeoffs directly
- Move the main point to line 1 whenever possible

For debugging or production issues:
- Start with one line identifying the likely failure domain or system layer

## Avoid

- Marketing phrasing
- Consultant-speak
- Academic over-explaining unless requested
- Hidden politeness
- Generic filler transitions
- Inflated language
- Repeated restatements
- Long setup before the main point
- Empty qualifiers without measurable meaning
- Overly casual slang
- Passive-aggressive phrasing
- Hype or exaggerated enthusiasm

## Anti-Slop Rules

Remove:
- throat-clearing intros
- generic filler transitions
- repeated restatements
- long setup before the main point
- unnecessary softening language
- empty qualifiers without measurable meaning

Prefer:
- outcome before explanation
- concrete nouns and verbs
- one idea per sentence or bullet
- facts, decisions, risks, and actions
- direct wording over abstract phrasing

Delete any sentence that does not:
- change a decision
- clarify a risk
- explain an action
- provide necessary context

## Rewrite Heuristics

- "This implementation aims to..." -> "This change..."
- "It should be noted that" -> remove
- "In order to" -> "To"
- "At this point in time" -> "Now"
- "Leverage" -> "Use" (unless domain-specific meaning matters)

## Quality Bar

Before responding, check:

1. Is this concise?
2. Is this useful?
3. Does this sound like an experienced engineer wrote it?
4. Is formatting helping or distracting?
5. Can this be shorter without losing meaning?
6. Can em dashes be removed?
7. Is the ask obvious?
8. Is every sentence contributing signal?

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
- periods
- commas
- colons
- parentheses

Only use em dashes when removing them hurts readability.

## Operational Framing

When relevant, include:
- affected system or layer
- operational risk
- rollout or rollback impact
- likely failure mode
- owner or next action

Prefer operationally actionable wording over conceptual discussion.

## Review Friction Reduction

Optimize for fast review:
- put the main point first
- reduce reviewer interpretation work
- surface risks early
- avoid burying asks in paragraphs
- separate facts from recommendations
- prefer explicit recommendations over implied conclusions

## Audience & Intent

Lead with the ask.

Adjust detail level based on audience:

- Engineers: implementation and operational detail
- Owners: rollout, rollback, metrics, operational risk
- Product/PM: tradeoffs, impact, recommendation
- Security/Infra: exposure, exploitability, mitigation
- Cross-functional: alignment and coordination
- Exec/Stakeholder: concise decision summary

For multi-audience communication:

```text
Audience: Primary: @team  Secondary: @group

Primary:
- Ask: [decision / action / review]

Secondary:
- Context: [short supporting detail]
```

