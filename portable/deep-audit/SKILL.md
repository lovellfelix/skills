---
name: deep-audit
description: Use when performing a comprehensive codebase health assessment before major refactoring, migration, production readiness review, or ownership transfer.
version: 0.2.0
portable: true
tags: [audit, architecture, quality, portable]
---

# Deep Audit

Full codebase health assessment: architecture, technical debt, security posture, and maintainability.

## Use when

- Comprehensive codebase health check before major refactoring or migration.
- Security compliance audit or pre-production review.
- Onboarding to an unfamiliar codebase and need a quality baseline.
- Evaluating long-term maintainability or ownership transfer.

## What I do

- Deep architectural review: coupling, cohesion, layer violations, dependency hygiene.
- Identify anti-patterns and technical debt hotspots with estimated remediation cost.
- Security posture assessment (OWASP Top 10, secrets, auth/authz gaps).
- Evaluate test coverage quality (not just quantity).
- Produce a prioritized findings report with blast radius estimates.

## Audit workflow

1. **Scope** — identify surfaces: APIs, data layer, auth, config, dependencies.
2. **Architecture pass** — map layers, entry points, data flows, and external dependencies.
3. **Security pass** — check OWASP Top 10, credential handling, input sanitization, authz boundaries.
4. **Quality pass** — complexity hotspots, test gaps, dead code, brittle patterns.
5. **Dependency audit** — outdated or vulnerable packages; license concerns.
6. **Findings report** — prioritized by risk with remediation recommendations.

## Output structure

### Executive summary
2–3 sentences: overall risk level, top concern, and recommended first action.

### Architecture findings
- Describe the actual structure discovered (not assumed).
- Flag layer violations, circular dependencies, God objects.
- Note scalability risks for current or projected load.

### Security findings
Use this format per issue:
```
[CRITICAL|HIGH|MEDIUM] Component — Vulnerability description
Risk: specific attack vector or data exposure.
Remediation: concrete fix with implementation note.
```

### Technical debt
- Hotspot files/modules (by complexity score or change frequency).
- Anti-patterns found (list with file references).
- Estimated effort to address (low/medium/high per item).

### Test coverage assessment
- What is covered well.
- Critical paths with no coverage.
- Integration / E2E gaps.

### Dependency health
- Outdated with known CVEs (CRITICAL).
- Outdated without CVEs (LOW).
- Unused or redundant packages.

### Priority remediation list
Ordered by risk × effort:
1. Must fix before production.
2. Should fix this sprint.
3. Technical debt backlog items.

## Constraints

- Be specific: file paths, function names, line numbers where possible.
- No vague "this could be improved" — state the risk and the fix.
- Distinguish between "breaks today" and "will cause problems at scale".
- Do not audit formatting or style enforced by existing linters.
