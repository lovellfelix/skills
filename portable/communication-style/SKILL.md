---
name: communication-style
description: Refine technical communication for clarity, brevity, and review usefulness. Use when writing PRs, documentation, RFCs, or Slack messages to improve clarity and reduce review friction.
version: 0.4.0
portable: true
tags: [communication, engineering-writing, pr-review, slack, clarity]
---

# Communication Style

## Style Defaults

- Concise by default. Cut filler aggressively.
- Direct and specific. Lead with the issue or ask.
- Active voice. Name actor and action.
- Engineering-first framing. Include behavior, risk, and next step.
- Fast scanning. Short lines, clean bullets, minimal prose.
- Tone: professional, slightly conversational. Never corporate.

## Constraints

- No marketing phrasing, politeness that hides the point, or vague hedging ("might", "potentially", "some" — unless uncertainty is real).
- Prefer "this will break when X" over indirect caution.
- Prefer "we should generalize this" over soft deferral.
- Output must be copy-paste ready.

## Modes

### Tighten (default)

Goal: preserve intent, reduce length, increase signal.

1. Remove hedging, filler, and repeated context.
2. Move the main point to line 1.
3. Replace vague language with concrete terms.
4. Keep only details that change action or understanding.

### PR Review

Structure every comment as:

```
Observation: what you see in code or behavior.
Impact: why it matters (bug, risk, operability, maintainability).
Recommendation: concrete change.
```

Example:
```
Observation: Retry loop has no backoff and retries forever.
Impact: Under downstream failure, this amplifies load and delays recovery.
Recommendation: Add capped exponential backoff and a max-attempt guard.
```

### Slack Rewrite

- One ask per message.
- Context only if needed for action.
- End with next step, owner, or question.
- Natural, not robotic.

### Technical Email / RFC Ask

- Subject/heading = outcome, not topic.
- Risk callout in line 1 if applicable.
- Decision ask must be explicit (not embedded in prose).

### Pi Response Polish

Use for cleaning up AI-generated completions before delivery:

- Lead with changed paths or result, not process recap.
- Max 3–5 bullets for task completion. No "next steps" section unless asked.
- No preamble ("Sure!", "Great question!") or restatement of the request.
- Skip "current status" and "suggested smoke test" unless relevant.
- Clarification needed? Use `ask_user` tool — don't guess and don't narrate ambiguity.

## Clarification pattern

When intent is unclear, ask directly:
- State your understanding.
- Name the specific ambiguity.
- Give 2 options with brief implications.
- State your default/recommendation.

Do not write paragraphs of "I could do X or Y" — one line per option is enough.

## Output structure

Return:
1. Rewritten text (copy-paste ready).
2. One-line note only if meaning changed due to ambiguity.
