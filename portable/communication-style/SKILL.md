---
name: communication-style
description: Use when writing PRs, documentation, RFCs, or Slack messages to improve clarity, brevity, and reduce review friction.
version: 0.5.0
portable: true
tags: [communication, engineering-writing, pr-review, slack, clarity]
---

# Communication Style

- Quick links
  - [Audience & Intent](#audience--intent)
  - [Tone Matrix](#tone-matrix)
  - [Style Defaults & Constraints](#style-defaults--constraints)
  - [Modes (Tighten / PR / Slack / RFC)](#modes)
  - [PR Review — Templates & Checklist](#pr-review-templates-checklist)
  - [Copy-paste Templates](#copy-paste-templates)
  - [Friction-reduction Rules](#friction-reduction-rules)
  - [Diplomatic Phrasing Cheatsheet](#diplomatic-phrasing-cheatsheet)
  - [Decision Ownership Guidance](#decision-ownership-guidance)
  - [Examples (PR / RFC / Slack)](#examples)

(Note: anchors follow GitHub-style slugification — lowercase; spaces → -; common punctuation mapped or removed. If your renderer uses different anchor rules, link to the exact header id.)

## Audience & Intent

Purpose: map common recipients to the writing goal and the expected action. Use this to shape level of detail, tone, and explicit asks.

- Engineers (peer): intent = actionable fix/merge. Short context (1 line), clear impact, exact change or code pointer, suggested reviewer(s).
  - Example: "Fixes crash when X. Replaces approach A with B. Request: review for perf and merge." 
- Maintainers / Owners: intent = risk-aware decision / approval. Include rollout plan, rollback, metrics, and owner.
  - Example: "Request approval to enable feature Y for 10% — rollout plan + metrics attached. Owner: @alice."
- Product / PM: intent = decision or tradeoff. High-level tradeoffs, user impact, recommended choice.
  - Example: "Recommendation: keep pagination server-side to reduce client complexity; impact on latency: +20ms." 
- Security / Infra: intent = provide evidence and mitigation. Include threat, affected surface, exploitability, and timeline.
  - Example: "Vuln: open S3 ACL. Impact: data exposure. Recommendation: tighten ACL + audit logs. ETA: 2 days."
- Cross-functional (Design/Docs): intent = collaboration / alignment. Provide user flows, examples, and ask for review or copy.
  - Example: "Updated onboarding flow; request design sign-off on copy and visuals."
- Exec / Stakeholder: intent = concise decision-ready summary. One-line summary, decision consequence, ask (approve/ack). 
  - Example: "Approve increased budget by 10% to accelerate Q3 launch; impact: +3 engineers, 6-week acceleration."

When writing, pick the primary audience and lead with their ask. If multiple audiences, add a one-line "Audience:" header.

Multi-audience convention (copy-paste)

When a message targets multiple audiences (e.g., engineers + product + docs), structure the message into two short blocks so each recipient can act quickly.

Audience: Primary: [team/role(s)]  Secondary: [team/role(s)]

Primary:
- 1–2 lines: direct ask, owner, ETA (actionable and minimal)

Secondary:
- 1–3 lines: background, links, non-actionable context for other stakeholders

Routing (bots / onboarding): include machine-friendly headers at the top when messages must be routed or consumed by automation. Prefer a single-line JSON value for X-Routing (recommended) — it's easy for machines to parse. Avoid semicolon-separated key=value pairs (e.g., bots=onboarding;channel=alerts); they are harder to parse reliably.

X-Routing: {"bots":["onboarding"],"channel":"alerts"}
X-Onboarding: true

Machine-routing schema examples (one-line):
```json
{"bots":["onboarding"],"channel":"alerts"}
```
```yaml
{bots: [onboarding], channel: alerts}
```

Copy-paste template:

```
Audience: Primary: @team-name  Secondary: @docs @product

Primary:
- Ask: [short outcome / decision required]  Owner: @[name]  ETA: [date/time]

Secondary:
- Context: [1–2 lines], Links: [doc/PR]

X-Routing: {"bots":["onboarding"],"channel":"alerts"}
X-Onboarding: true
```

Keep the Primary block <=2 sentences. Put long rationale or logs only in the Secondary block or a linked document.

## Tone Matrix

Machine-readable (YAML)

```yaml
tones:
  - tone: Direct
    use-case: code/PRs
    voice: active
    length: "1-3 sentences + checklist/patch"
    opening_template: "Fix crash in X by adding backoff."

  - tone: Collaborative
    use-case: reviews, cross-team asks
    voice: active
    length: "2-4 sentences + specific asks"
    opening_template: "I'd like input on two options for X — pairing welcome."

  - tone: Diplomatic
    use-case: conflict, sensitive review
    voice: passive-allowed
    length: "2-5 sentences"
    opening_template: "I noticed X and wanted to propose a small change to reduce risk."

  - tone: Persuasive
    use-case: roadmaps, exec asks
    voice: active
    length: "1-3 bullets + one-line ask"
    opening_template: "Recommend we invest in Y; expected ROI: 3x in 12 months."

  - tone: Informational
    use-case: status updates
    voice: active
    length: "3-6 bullets"
    opening_template: "Status: migration 75% done. Next: cutover on Tue. Owner: @bob."
```

Human-readable table

| tone | use-case | active/passive | length | opening_template |
|---|---:|---|---|---|
| Direct | code/PRs | active | 1–3 sentences + checklist/patch | "Fix crash in X by adding backoff." |
| Collaborative | reviews, cross-team asks | active | 2–4 sentences + asks | "I'd like input on two options for X — pairing welcome." |
| Diplomatic | conflict, sensitive review | passive-allowed | 2–5 sentences | "I noticed X and wanted to propose a small change to reduce risk." |
| Persuasive | roadmaps, exec asks | active | 1–3 bullets + ask | "Recommend we invest in Y; expected ROI: 3x in 12 months." |
| Informational | status updates | active | 3–6 bullets | "Status: migration 75% done. Next: cutover on Tue. Owner: @bob." |

Tone examples (opening lines):
- Direct: "Fix: NullPointer in UserService when email is missing — guard added."
- Collaborative: "Question: should we centralize validation in the API or the client? I lean API for consistent errors."
- Diplomatic: "Suggestion: consider adding a max retry to reduce downstream load (see rationale)."

## Style Defaults & Constraints

- Concise by default. Cut filler aggressively.
- Direct and specific. Lead with the issue or ask.
- Active voice. Name actor and action.
- Engineering-first framing. Include behavior, risk, and next step.
- Fast scanning. Short lines, clean bullets, minimal prose.
- Tone: professional, slightly conversational. Never corporate.

Constraints: avoid marketing phrasing, hidden politeness, and vague hedging unless uncertainty is real. Output must be copy-paste ready.

## Modes

See small-mode rules below for common contexts.

- Tighten (default)
  - Goal: preserve intent, reduce length, increase signal.
  - Steps: 1) Move main point to line 1. 2) Remove filler. 3) Replace vague words with specifics.

- PR Review (expanded)
  - Structure every comment as: Observation / Impact / Recommendation.
  - Keep each comment <= 4 sentences.
  - Always include a suggested code change or link to a line number.

- Slack Rewrite
  - One ask per message. End with next step/owner.

- Technical Email / RFC Ask
  - Subject = outcome. First line = decision or risk. Attach short rollback/metrics plan.

- Pi Response Polish
  - Max 3–5 bullets for completion. No unnecessary preamble. If ambiguous, ask (use the Clarification pattern).

<a id="pr-review-templates-checklist"></a>

## PR Review — Templates & Checklist

Purpose: reduce back-and-forth and make reviews action-oriented.

Comment template (copy-paste ready):

```
Observation: [what you see]
Impact: [why it matters]
Recommendation: [exact change, test, or link to code]
```

Inline suggestion template (GitHub suggested change block):

```suggestion
// short code snippet replacement, with one-line comment explaining why
```

Example suggested change (include simple language marker in a short comment):

```suggestion
// (language: js)
function sanitize(input) {
-  return input;
+  return String(input).trim();
}
```

PR description template (use in every PR body):

Note: Title MUST be a short outcome (use 6–10 words max; focus on the end result).

```
Title: <short outcome-focused title>

Summary: 1–2 lines describing the change and user-visible effect.

Why: short rationale and tradeoffs.

Testing: how this was tested (unit, integration, manual steps).

Rollout: rollout plan, feature flag (if any), and rollback steps.

Impact: any infra, perf, or data-migration impacts.

Owners: @author, reviewers: @team
```

Review checklist (author-run before requesting review):

- [ ] Title is outcome-focused and concise
- [ ] PR body follows template
- [ ] Tests added/updated or explicit reason for omission
- [ ] Changes limited to stated scope
- [ ] Migration steps (if any) included and idempotent
- [ ] Performance/regression risk noted
- [ ] Security considerations noted
- [ ] CI green locally or in CI

Reviewer checklist (use when reviewing):

- [ ] Does the PR do what the title/summary claim?
- [ ] Are tests meaningful and sufficient?
- [ ] Any larger design concerns — call them out with suggested alternatives
- [ ] Is rollout/rollback plan adequate?
- [ ] Are there obvious performance, security, or operability risks?
- [ ] Small nits: prefer inline suggested changes, not noise comments

Escalation signals (request owner/maintainer attention):
- Data migration or irreversible change
- Security/PII surface touched
- >10 files or broad refactor without prior design sync
- Rolling back would be high-cost or slow

## Copy-paste Templates

Below are ready-to-send templates. Replace bracketed tokens.

PR description

Note: Title MUST be a short outcome (6–10 words max; state the result).

```
Title: [Short outcome-focused title]

Summary: [1–2 lines: what changed and why]

Why: [short rationale and tradeoffs]

Testing: [how to validate, steps or tests]

Rollout: [flag/percentage, migration steps, rollback]

Impact: [perf, infra, data]

Owners: @[author] reviewers: @[team]
```

RFC / Decision request (short)

```
Title: [Decision: short outcome]

Context: [1–3 lines background]

Options considered: [A] short, [B] short

Recommendation: [explicit decision and owner]

Risks & mitigations: [top 2]

Ask: [approve / review by date / feedback]
```

Slack status / ask

```
Context: [1 line]

Update: [1–2 bullets – current status]

Ask: [what I need, owner, ETA]
```

Technical email (to infra/security/product)

Include To / CC / Contact lines for clear escalation routing.

```
To: [team-or-personal-alias]
CC: [additional-stakeholders]
Contact: [primary contact name / @handle / email]
Subject: [Outcome-first subject]

1-line summary: [decision or issue + high-level impact]

Details: [2–4 bullets: why, mitigation, ETA]

Action: [what you need from recipient; escalate to Contact if no reply in X hours]
```

Clarification question (to requestor)

```
Understanding: [one line summary of my current assumption]

Ambiguity: [single-sentence specific uncertainty]

Options: [1) do X — effect. 2) do Y — effect]

Recommendation: [my default choice]
```

## Friction-reduction Rules

Small rules that reduce reviewer friction and save time.

- Keep PRs < 300 lines of net change when possible.
- One logical change per PR (fix + refactor = separate PRs).
- Run tests locally and link the passing CI in the PR body.
- Prefer suggested change blocks for nits over comments.
- Add tests or a short manual validation recipe.
- Mark WIP/Preview with a clear prefix and avoid requesting formal review.
- If touch is broad (>10 files), include a short design note in the PR body.
- Use feature flags for behavior changes when rollout/rollback matters.
- Document and version migrations; include an idempotent migration plan.

## Diplomatic Phrasing Cheatsheet

Use these patterns when you need to be constructive.

- Instead of "This is wrong", write "Suggestion: consider..." with rationale.
- Instead of "You missed X", write "Observation: X is absent; recommendation...".
- Replace blame with facts: "I see that X does Y under Z".
- Offer pairing: "Happy to pair on this if helpful".
- Close the loop: "If we choose to keep this, I'll follow up with...".

## Decision Ownership Guidance

Make decisions explicit and assign an owner.

- Decision types: Operational (owner = team), Design (owner = author/architect), Exec (owner = PM/leader), Security (owner = SecOps).
- For ambiguous ownership: default to the author for technical choices; default to PM for scope/priority.
- When in doubt, tag the suggested owner in the PR and ask for a confirm or handoff.

Phrases to assign ownership:
- "Decision: enable X in prod — owner: @alice (please confirm by EOD)."
- "If @alice doesn't respond, owner becomes @team-leads for approval." 

## Examples

Example PR body

```
Title: Fix crash when email is missing in UserService

Summary: Adds null-check and unit tests to prevent NPE when email is missing from user profile.

Why: Missing email caused crash in onboarding flow for ~0.5% of users.

Testing: Unit tests added; manual repro steps included.

Rollout: Deploy behind feature flag for 24h canary, then 100%.

Impact: Low perf cost; no migration required.

Owners: @author reviewers: @team
```

Example Slack update

```
Context: Migration of review-db to replica cluster

Update: Migration 75% complete; remaining table copy scheduled at 03:00 UTC.

Ask: Will cause 5–10m read-only window; @infra please confirm maintenance window.
```
