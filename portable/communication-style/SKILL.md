---
name: communication-style
description: Use when writing PRs, documentation, RFCs, Slack messages, reviews, incident updates, blog posts/field notes, and technical communication to improve clarity, brevity, and reduce review friction.
metadata:
  version: 0.14.0
  portable: true
  tags: [communication, engineering-writing, pr-review, slack, clarity, blog]
---

# Communication Style

Write like a strong Sr. Engineer / Sr. Staff Engineer communicator.

Clear, concise, direct, high-signal. Professional but natural. Confident without sounding corporate or inflated. Substance over flourish.

Use active voice. Name the actor and action. State behavior, risk, and next step clearly. Format for fast scanning.

Output must be copy-paste ready.

## Use when

- Rewriting technical updates for clarity and brevity.
- Drafting PR notes, RFC comments, review feedback, or incident updates.
- Writing or editing blog posts and field notes (personal or team).
- Tightening wording so asks, risks, and decisions are obvious.

## When not to use

- You need domain-specific technical analysis rather than wording help.
- The user asks for a distinct voice that conflicts with these defaults.

## Related Skills

- `documentation` for structured engineering docs.
- `incident-postmortem` for blameless incident writeups.
- `design-doc-review` for design/RFC quality checks.

## Detailed Reference

`writing-guide.md` (in this skill directory) covers what this checklist doesn't: per-format structures (email, RFC, implementation prompt, incident, blog), the evidence/ownership/metrics/tradeoff model, causality, and the revision-pass workflow. Read it before drafting long-form or high-stakes material (RFCs, postmortems, blog posts); for quick edits (PR notes, Slack messages), this file is usually enough. Its rules and this file's don't overlap, apply both, in either order.

## Flag Inconsistencies

Determinism, not just brevity, is the goal. If the source material or the request is internally inconsistent, or asks for something that conflicts with a rule here or in `writing-guide.md`, name the specific rule and the specific conflict, then ask or flag it rather than silently resolving it one way. Examples: a draft hedges a fact it also states as confirmed (`writing-guide.md` evidence-tiers rule); a request wants both terse bullets and exhaustive detail; a request wants leadership/impact framing where the input describes an individual contribution (`writing-guide.md` ownership rule). "This sounds off" is not a flag; name the rule.

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
- Inflated language
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

- make the outcome clear early, but vary sentence structure naturally
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
6. Does this contain zero em dashes (—)?
7. Is there at most one clause-level colon per paragraph?
8. Is the ask obvious?
9. Is every sentence contributing signal?

## Formatting Rules

- Use short paragraphs and short bullet lists
- Use bullets only when they improve scanning
- Avoid tables unless clearly the best format
- Avoid decorative formatting
- Keep whitespace clean and readable
- Avoid excessive nesting
- Do not repeat points

### Prose vs. Bullets by Genre

This determines whether a piece opens with a bulleted list or stays in prose. Pick by genre, not by preference in the moment:

- **Narrative/explanatory** (incident notes, postmortems, root-cause explanations, blog/field-note passages): prose only. State the causal chain in full sentences; do not break it into bullets even when it has multiple steps.
- **Change/action content** (PR descriptions, changelists, task summaries): one-line statement of what the change does, then a bulleted list of the changes, then a one-line verification/test statement. Do not expand the change list into prose.

If a piece mixes both (e.g., an RFC with a rationale section and a rollout checklist), apply prose to the rationale and bullets to the checklist within the same document.

### Em Dash Rule

Do not use em dashes (—). This is a hard rule, not a preference. There is no readability exception. If a draft contains one, rewrite the sentence; do not keep it and justify it.

Deterministic replacements, in order of fit:

1. Two independent clauses -> split into two sentences with a period.
2. A list or appositive aside -> use a comma.
3. A parenthetical aside -> use parentheses.
4. A clause that explains or expands the one before it -> new sentence. Use a colon only if it introduces a genuine list or definition and the paragraph has no clause-level colon yet (see Colon Rule).

Before finishing any draft, scan the text for `—` and `--` and replace every instance. Zero em dashes is the only passing state.

### Colon Rule

A colon is not a default em-dash substitute. Overusing it moves the crutch punctuation one character to the left and produces the same skimmable-fragment problem the em-dash rule exists to fix.

- Default to a period (two sentences) or a comma (apposition, list lead-in) when the second clause can stand on its own.
- Reserve the colon for a genuine list or definition introduction: a short label followed by an enumerated series (`Three things: X, Y, Z`), or a term followed by its definition. Not for connecting two clauses that could just as easily be two sentences.
- Hard limit: at most one clause-level colon per paragraph. Timestamps, ratios, URLs, and code do not count. If a paragraph already has one, rewrite every further instance as a period or comma.
- After the em-dash pass, scan every draft for `:` and enforce the limit.

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

## Blog Posts & Field Notes

All rules above apply. See `writing-guide.md` §19 for the full structure model (problem, context, what was tried, what changed, lesson). This adds:

- Prose over bullet-heavy scaffolding. Flowing paragraphs are the default; use a bulleted list only for a genuine enumeration (steps, options), not as a substitute for a sentence.
- No formulaic AI-tell structure: no "Final thought" / "Key takeaway" closing section, no "It's not X, it's Y" framing, no restating the title as the closing line.
- No generic outcome lists ("Faster X. Better Y. Less Z."): if the result matters, say what specifically changed, with enough detail that it couldn't apply to any other project.
- The em dash rule applies without exception. Long-form is where em dashes accumulate fastest, so check this last, after every other pass.
- Preserve the author's actual voice and specific details (names, numbers, dates, tools) exactly as given. Tighten grammar and structure; do not smooth away the specifics that make it a field note instead of a generic explainer.
