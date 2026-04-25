---
name: rfc-blueprint
description: Write RFC and technical design documents using a strict blueprint format. Use for RFC, design doc, technical proposal, or architecture document requests. More opinionated than the rfc skill.
version: 0.1.0
portable: true
tags: [rfc, architecture, design, portable]
---

# RFC Blueprint Format

## Document Structure (strict order)

### 1. Header

Title, Author, Date, Status (Draft / In Review / Accepted / Superseded), Target Audience.

### 2. Motivation (3 sentences maximum)

State the problem. State why it matters now. State what breaks or degrades if unaddressed.
Do not pad. Do not restate the title.

### 3. Non-Negotiables

Bullet list of hard constraints: correctness requirements, compatibility requirements, operational requirements (uptime, on-call burden), security requirements.
These are the acceptance criteria the solution must satisfy unconditionally.

### 4. Architecture

Lead with a Mermaid `flowchart LR` diagram. Minimal nodes. Clean, labeled edges.
Follow with prose describing data flow, component responsibilities, and interaction boundaries.
Do not describe implementation details here — those go in the Appendix.

### 5. Risks (include only if material risks exist)

One row per risk: description, likelihood, mitigation, owner.

### 6. Appendix

Include subsections as needed:

- Alternatives Considered — at least 2 alternatives with explicit rationale for rejection
- State Model — if the design involves state transitions
- Algorithms — if non-obvious algorithmic choices are made
- Execution Flow — step-by-step sequence for key paths (use Mermaid `sequenceDiagram` if helpful)
- Open Questions — unresolved decisions with owner and due date

## Tone and Style

- Target audience: senior/staff engineers. Assume systems knowledge. Skip basic definitions.
- Be precise and terse. Omit filler phrases.
- Active voice. Present tense for current state, future tense for proposed behavior.
- Avoid hedge stacking.

## Mermaid Diagrams

- Use `flowchart LR` for architecture. Never TD.
- Minimal nodes: include only components the reader needs to reason about the design.
- Label edges with the data or signal crossing the boundary.
- Apply `classDef` styling if more than 5 nodes.

## Do Not

- Do not write an executive summary or abstract.
- Do not pad with background that belongs in a wiki.
- Do not include implementation timelines.
