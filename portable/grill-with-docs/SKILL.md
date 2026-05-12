---
name: grill-with-docs
description: Use when stress-testing a plan against existing domain language and decisions while capturing clarified terms and trade-offs in docs.
metadata:
  version: 0.1.0
  portable: true
  tags: [planning, domain-language, adr, documentation, portable]
---

# Grill with Docs

Run a disciplined grilling loop before implementation.

## Core loop

1. Ask one high-value question at a time; wait for response before the next.
2. If the answer is discoverable in code/docs, verify first instead of asking.
3. For each question, provide a recommended answer and tradeoff.
4. Keep drilling until terms, boundaries, and decisions are precise.

## Documentation discipline

- Use existing `CONTEXT.md` and `docs/adr/` when present.
- If missing, create them only when there is real content to record.
- Update domain terms inline as they are resolved (don’t batch later).
- Propose an ADR only when all are true:
  - hard to reverse
  - surprising without context
  - result of a real tradeoff

## Language checks

- Call out conflicts with existing glossary terms immediately.
- Replace fuzzy terms with canonical names.
- Pressure-test with concrete scenarios and edge cases.
- Surface code-vs-stated-behavior mismatches explicitly.

## Output

- Final clarified terminology list
- Confirmed decisions and open questions
- Any docs updated (`CONTEXT.md`, ADRs) with paths
