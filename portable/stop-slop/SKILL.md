---
name: stop-slop
description: Use when rewriting AI-sounding drafts into concise, human engineering writing that matches existing communication-style and documentation guidance.
version: 0.1.0
portable: true
tags: [writing, editing, clarity, engineering-communication]
---

# Stop Slop

Use this as a final polish pass after applying `communication-style` and, when relevant, `documentation`.

Goal: remove generic AI phrasing, repetition, and padded prose without changing technical meaning.

## How It Complements Existing Skills

- Keep `communication-style` as the primary tone/format standard.
- Keep `documentation` as the primary structure/operations standard.
- Use this skill only to tighten wording and remove AI artifacts.

## Slop Patterns to Remove

- Throat-clearing intros ("Certainly", "Great question", "Here’s what we’ll do").
- Empty qualifiers ("robust", "seamless", "comprehensive") unless measurable.
- Repeated restatements of the same point.
- Generic filler transitions ("In conclusion", "It is important to note").
- Overly long sentences when a direct sentence works.
- Unnecessary hedging when confidence is justified by evidence.

## Rewrite Rules

1. Lead with outcome, not setup.
2. Prefer concrete nouns and verbs over abstract phrasing.
3. Keep one idea per bullet/sentence where possible.
4. Delete any sentence that does not change a decision or action.
5. Keep examples only when they clarify a decision.
6. Preserve caveats that affect risk; remove softening fluff.

## Quick Before/After Heuristics

- "This implementation aims to..." -> "This change..."
- "It should be noted that" -> remove.
- "In order to" -> "To".
- "At this point in time" -> "Now".
- "Leverage" -> "use" (unless domain-specific meaning is needed).

## Final Check (10-second pass)

- Would a senior engineer say this in a PR or incident thread?
- Is each line either a fact, decision, risk, or action?
- Can any line be deleted without losing meaning?
