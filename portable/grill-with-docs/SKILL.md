---
name: grill-with-docs
description: Use when stress-testing a plan or design against existing domain language and decisions, or when reviewing architecture for deep-module, test-seam and locality opportunities, capturing clarified terms and trade-offs in docs.
metadata:
  version: 0.2.0
  portable: true
  tags: [planning, domain-language, adr, documentation, architecture, refactoring, portable]
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

## Architecture review mode

When asked to find structural improvements rather than test a specific plan:

- Read context docs and ADRs if present; otherwise use code, tests and history.
- Look for shallow modules, pass-through abstractions, poor test seams, coupling across seams.
- Deletion test: if removing a module just moves complexity into callers, it earned its place; if nothing changes, it was shallow.
- Per candidate: modules involved, current friction, proposed deepening, locality and leverage gained, test-seam improvement, ADR conflict (only if worth reopening).
- Do not implement. Ask which candidate to drill into, then run the core loop on its seam and interface.

## Output

- Final clarified terminology list
- Confirmed decisions and open questions
- Any docs updated (`CONTEXT.md`, ADRs) with paths
