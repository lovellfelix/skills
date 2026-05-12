---
name: improve-codebase-architecture
description: Use when reviewing architecture for deep-module opportunities, better test seams, and stronger locality/leverage across modules.
metadata:
  version: 0.1.0
  portable: true
  tags: [architecture, refactoring, testability, modularity, portable]
---

# Improve Codebase Architecture

Find high-leverage deepening opportunities that improve testability and maintainability.

## Vocabulary

Use consistent terms:
- **Module**: unit with interface + implementation
- **Interface**: what callers must know (types, invariants, error modes, ordering)
- **Depth**: leverage provided by interface
- **Seam**: place where behavior can change without editing every caller
- **Adapter**: concrete implementation behind a seam
- **Locality**: complexity concentrated in one place

## Review flow

1. Establish context sources:
   - If present, read repository context docs (configurable names/paths like `CONTEXT.md`, `docs/context.md`, or team equivalents).
   - If present, read relevant ADRs (`docs/adr/`, `adr/`, or project-standard architecture decision docs).
   - If context docs are absent, continue with code + tests + commit history as fallback context.
2. Explore friction points:
   - shallow modules
   - pass-through abstractions
   - poor test seams
   - tight coupling across seams
3. Apply deletion test: if removing a module just moves complexity into callers, it was valuable; if nothing changes, it was shallow.

## Output candidates

For each candidate provide:
- Files/modules involved
- Current friction
- Proposed deepening change
- Expected leverage/locality gains
- Test-seam improvement
- ADR conflict note (only when materially worth reopening)

Do not jump to implementation. Ask which candidate to drill into first, then run a grilling loop to sharpen seam/interface design.
