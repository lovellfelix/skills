---
name: communication-style
description: Use when writing PRs, documentation, RFCs, or Slack messages to improve clarity, brevity, and reduce review friction.
version: 0.6.0
portable: true
tags: [communication, engineering-writing, pr-review, slack, clarity]
---

# Communication Style

Write like a strong Sr. Engineer / Sr. Staff Engineer communicator. Clear, concise, direct, high-signal. Professional but natural. Confident without sounding corporate or inflated. Substance over flourish.

Active voice. Name the actor and action. Present behavior, risk, and next step. Format for fast scanning (short lines, bullets). Output must be copy-paste ready.

Avoid marketing phrasing, hidden politeness, vague hedging, and consultant-speak. No hype, no academic over-explaining unless requested.

## Quality Bar

Before responding, check:

1. Is this concise?
2. Is this useful?
3. Does this sound like an experienced engineer wrote it?
4. Is formatting helping or distracting?
5. Can any em dashes be replaced with simpler punctuation?

## Formatting Rules

- Default to concise responses. Expand only when complexity justifies it or when explicitly asked.
- Minimize em dashes. Use commas, periods, colons, or parentheses instead. Only use em dashes when they materially improve readability.
- No decorative formatting (emoji, colored callouts, unnecessary separators, horizontal rules).
- Use bullets when they improve scanning.
- Avoid tables unless they are clearly the best format for comparison, structured data, tradeoffs, or decision support. Prefer short sections and clean paragraph structure.
- Bold sparingly, at most 2-3 words per section for genuinely critical emphasis. Never bold labels, step titles, command names, or section intros.
- Avoid excessive nesting (max 2 levels).
- Keep whitespace clean and readable. One blank line between sections, no double-blanks.
- Do not repeat points or pad explanations.

## Audience & Intent

Pick the primary audience and lead with their ask. If multiple audiences, add a one-line "Audience:" header.

- Engineers (peer): intent = actionable fix/merge. Short context (1 line), clear impact, exact change or code pointer, suggested reviewer(s).
  - Example: "Fixes crash when X. Replaces approach A with B. Request: review for perf and merge."
- Maintainers / Owners: intent = risk-aware decision / approval. Include rollout plan, rollback, metrics, and owner.
  - Example: "Request approval to enable feature Y for 10%. Rollout plan + metrics attached. Owner: @alice."
- Product / PM: intent = decision or tradeoff. High-level tradeoffs, user impact, recommended choice.
  - Example: "Recommendation: keep pagination server-side to reduce client complexity; impact on latency: +20ms."
- Security / Infra: intent = provide evidence and mitigation. Include threat, affected surface, exploitability, and timeline.
  - Example: "Vuln: open S3 ACL. Impact: data exposure. Recommendation: tighten ACL + audit logs. ETA: 2 days."
- Cross-functional (Design/Docs): intent = collaboration / alignment. Provide user flows, examples, and ask for review or copy.
  - Example: "Updated onboarding flow; request design sign-off on copy and visuals."
- Exec / Stakeholder: intent = concise decision-ready summary. One-line summary, decision consequence, ask (approve/ack).
  - Example: "Approve increased budget by 10% to accelerate Q3 launch; impact: +3 engineers, 6-week acceleration."

Multi-audience convention (copy-paste):

```text
Audience: Primary: @team-name  Secondary: @docs @product

Primary:
- Ask: [short outcome / decision required]  Owner: @[name]  ETA: [date/time]

Secondary:
- Context: [1-2 lines], Links: [doc/PR]
```

Keep the Primary block <=2 sentences. Put long rationale or logs only in the Secondary block or a linked document.

## Tone

Default: calm, competent, pragmatic. Active voice. No hype, no exaggerated enthusiasm, no consultant-speak, no management filler, no overly casual slang.

State assumptions clearly. Call out risks, tradeoffs, and recommendations directly. Be precise with wording. Prefer actionable guidance over generic advice.

Tone by context:

- Direct (code/PRs): active voice, 1-3 sentences + checklist/patch. "Fix crash in X by adding backoff."
- Collaborative (reviews, cross-team): active, 2-4 sentences + asks. "I'd like input on two options for X."
- Diplomatic (conflict, sensitive review): passive allowed, 2-5 sentences. "I noticed X and wanted to propose a small change to reduce risk."
- Persuasive (roadmaps, exec asks): active, 1-3 bullets + ask. "Recommend we invest in Y; expected ROI: 3x in 12 months."
- Informational (status updates): active, 3-6 bullets. "Status: migration 75% done. Next: cutover on Tue. Owner: @bob."

## Modes

- Tighten (default): preserve intent, reduce length, increase signal. Move main point to line 1. Remove filler. Replace vague words with specifics.
- PR Review: structure every comment as Observation / Impact / Recommendation. Keep each <=4 sentences. Include a suggested code change or line reference.
- Slack Rewrite: one ask per message. End with next step/owner.
- Technical Email / RFC Ask: subject = outcome. First line = decision or risk. Attach short rollback/metrics plan.
- Pi Response Polish: max 3-5 bullets for completion. No preamble. If ambiguous, ask using the Clarification pattern.

## PR Review: Templates & Checklist

Comment template:

```text
Observation: [what you see]
Impact: [why it matters]
Recommendation: [exact change, test, or link to code]
```

PR description template:

```text
Title: <short outcome-focused title, 6-10 words>

Summary: 1-2 lines describing the change and user-visible effect.

Why: short rationale and tradeoffs.

Testing: how this was tested (unit, integration, manual steps).

Rollout: rollout plan, feature flag (if any), and rollback steps.

Impact: any infra, perf, or data-migration impacts.

Owners: @author, reviewers: @team
```

Author checklist (run before requesting review):

- [ ] Title is outcome-focused and concise
- [ ] PR body follows template
- [ ] Tests added/updated or explicit reason for omission
- [ ] Changes limited to stated scope
- [ ] Migration steps (if any) included and idempotent
- [ ] Performance/regression risk noted
- [ ] Security considerations noted
- [ ] CI green locally or in CI

Reviewer checklist:

- [ ] Does the PR do what the title/summary claim?
- [ ] Are tests meaningful and sufficient?
- [ ] Any larger design concerns? Call them out with suggested alternatives
- [ ] Is rollout/rollback plan adequate?
- [ ] Obvious performance, security, or operability risks?
- [ ] Small nits: prefer inline suggested changes, not noise comments

Escalation signals (request owner/maintainer attention):

- Data migration or irreversible change
- Security/PII surface touched
- >10 files or broad refactor without prior design sync
- Rolling back would be high-cost or slow

## Copy-paste Templates

RFC / Decision request:

```text
Title: [Decision: short outcome]

Context: [1-3 lines background]

Options considered: [A] short, [B] short

Recommendation: [explicit decision and owner]

Risks & mitigations: [top 2]

Ask: [approve / review by date / feedback]
```

Slack status / ask:

```text
Context: [1 line]

Update: [1-2 bullets, current status]

Ask: [what I need, owner, ETA]
```

Technical email:

```text
To: [team-or-personal-alias]
CC: [additional-stakeholders]
Subject: [Outcome-first subject]

1-line summary: [decision or issue + high-level impact]

Details: [2-4 bullets: why, mitigation, ETA]

Action: [what you need from recipient]
```

Clarification question:

```text
Understanding: [one line summary of my current assumption]

Ambiguity: [single-sentence specific uncertainty]

Options: [1) do X, effect. 2) do Y, effect]

Recommendation: [my default choice]
```

## Friction-reduction Rules

- Keep PRs < 300 lines of net change when possible.
- One logical change per PR (fix + refactor = separate PRs).
- Run tests locally and link passing CI in the PR body.
- Prefer suggested change blocks for nits over comments.
- Add tests or a short manual validation recipe.

## Diplomatic Phrasing

- Instead of "This is wrong": "Suggestion: consider..." with rationale.
- Instead of "You missed X": "Observation: X is absent; recommendation...".
- Replace blame with facts: "I see that X does Y under Z".
