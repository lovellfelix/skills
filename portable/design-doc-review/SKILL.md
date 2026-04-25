---
name: design-doc-review
description: Review a technical design document or RFC as a senior/staff engineer before sharing. Invoke after drafting to catch structural, clarity, and completeness issues.
version: 0.1.0
portable: true
tags: [review, design, rfc, portable]
---

# Design Doc Review

Review the design document or RFC in the current context. Evaluate against these criteria and output findings as P0/P1/P2.

## P0 — Blocks sharing (must fix)

- Motivation section is vague, absent, or longer than 3 sentences
- Non-Negotiables missing or stated as preferences rather than hard constraints
- Architecture diagram absent or describes implementation rather than component boundaries
- Alternatives section absent or only one alternative listed

## P1 — Should fix before review

- Prose contradicts the diagram
- Open questions exist but have no owner or resolution date
- Tone is padded — abstract, executive summary, or boilerplate present
- Document structure deviates from blueprint without justification
- Risks listed without mitigation or owner

## P2 — Minor polish

- Passive voice in key claims
- Hedge stacking present
- Appendix sections present but empty
- Mermaid diagram uses TD instead of LR

## Output format

- One finding per line
- Format: `[P0|P1|P2] <Section> — <finding> — <recommended fix>`
- End with a one-sentence overall readiness assessment
