---
name: rfc
description: Use when proposing a significant engineering change and need a tight, reviewable RFC focused on constraints, decisions, and rollout safety.
version: 0.3.0
portable: true
tags: [rfc, architecture, design, tradeoffs, rollout]
---

# RFC

## Style Defaults

- Tight core doc; optimize for review speed.
- Lead with problem and constraints.
- Focus on behavior, tradeoffs, and operational impact.
- Keep language direct and implementation-relevant.
- Push deep detail into appendix by default.
- Each section answers a reviewer question.
- Prefer describing failure behavior before happy path when risk is high.

## What I Do

- Build RFCs around decisions reviewers can validate quickly.
- Keep scope focused and non-negotiables explicit.
- Surface tradeoffs, risks, and failure implications early.
- Align architecture with rollout, validation, and recovery plans.

## When to Use Me

- Proposing architecture or behavior changes with production impact.
- Choosing between approaches with meaningful tradeoffs.
- Needing reviewer alignment before implementation.
- Replacing long drafts with tight, decision-oriented RFCs.

## Output Structure

1. Motivation
2. Non-Negotiables / Constraints
3. Proposed Approach
4. Key Decisions / Tradeoffs
5. Risks
6. Rollout / Validation
7. Appendix (optional)

## Steps

1. Confirm scope and constraints with user.
2. Draft each section in order: Motivation → Non-Negotiables → Proposed Approach → Key Decisions → Risks → Rollout → Appendix.
3. Apply Output Structure rules (each section scannable in <30s, bullets over paragraphs).
4. Verify no filler language, no restating obvious context.
5. Write output to `{filename}.md` or return inline.

## Completion Markers

Every RFC MUST end with:
✓ RFC_COMPLETE: {title} ({section_count} sections)
✓ DECISIONS: {decision_count} key decisions documented

- Each section must be scannable in <30 seconds.
- Prefer bullets over paragraphs.
- Avoid restating obvious context.
- Assume informed reviewers.
- No narrative or academic writing.

Section expectations:

- Motivation: 2–4 sentences (problem, impact, why now)
- Constraints: explicit bullets (SLO, scale, latency, etc.)
- Approach: runtime behavior and architecture
- Risks: failure modes + recovery
- Rollout: steps, observability, rollback

## Guidelines / Constraints

- Keep core RFC concise.
- Include only details that affect decisions.
- Highlight tradeoffs clearly.
- Include operational implications.
- Move deep technical detail to appendix.

## Explicitly Avoid

- Generic RFC templates
- Overlong design sections
- Ceremony-heavy structure
- Filler language
