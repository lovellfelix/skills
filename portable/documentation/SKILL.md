---
name: documentation
description: Use when writing or updating engineering documentation and want it grounded in runtime behavior rather than aspirational prose.
version: 0.3.0
portable: true
tags: [documentation, engineering, runbook, operations, architecture]
---

# Documentation

## Style Defaults

- Concise, practical, and scan-friendly.
- Lead with purpose and operational relevance.
- Describe actual system behavior, not intent-only design.
- Prioritize constraints, failure modes, and recovery paths.
- Treat docs as contracts with implementers and on-call engineers.

## What I Do

- Draft or tighten design, implementation, and architecture docs.
- Write operational docs: runbooks, rollout notes, migration notes.
- Surface runtime behavior: latency, dependencies, backpressure, retries.
- Make failure handling and rollback steps explicit.
- Remove low-signal prose and keep docs maintainable.
- Define expected baselines (normal vs degraded) when relevant.

## When to Use Me

- A change needs a design or implementation doc people can review quickly.
- A service needs runbook-grade operational documentation.
- A rollout or migration needs clear execution and rollback instructions.
- Existing docs are correct but too long, vague, or stale.

## Output Structure

Use this structure unless user asks otherwise:

1. Purpose
2. Scope
3. System Overview
4. Key Design Decisions
5. Runtime / Operational Behavior
6. Constraints
7. Failure Modes / Operational Considerations
8. Usage / Interaction (if needed)

## Output Format

- Use short, direct sections with no unnecessary prose.
- Each section should be scannable in <30 seconds.
- Prefer bullets over paragraphs.
- Avoid narrative explanations unless they affect decisions.
- Assume informed engineers.

## Guidelines / Constraints

- Keep sections short; cut background that does not affect implementation or ops.
- Prefer concrete behavior over abstract claims.
- Include observable signals: metrics, logs, alerts, dashboards.
- Include rollout and rollback where behavior can impact production.
- Document idempotency, retry semantics, timeout boundaries, and capacity limits.
- For runbooks, optimize for stressed on-call usage: symptom -> checks -> action -> escalation.
- Do not default to tutorial framing or generic API boilerplate.
- Do not "document everything"; document what changes decisions and operations.

## Output Mode Hints

- Design / Architecture: emphasize decisions, tradeoffs, and invariants.
- Implementation Doc: emphasize interfaces, dependencies, and behavior under load.
- Runbook: emphasize detection, triage, mitigation, rollback, and verification.
- Migration / Rollout: emphasize sequencing, safety checks, blast radius, and recovery.
