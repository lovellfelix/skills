---
name: code-review
description: Performs comprehensive code review with security scanning and language auto-detection.
version: 0.2.0
portable: true
tags: [review, quality, security, portable]
---

# Code Review

Structured review focused on bugs, risk, and actionable improvements — not style opinions.

## What I do

- Auto-detect language (Python, JS/TS, Go, Kotlin, Shell) and apply appropriate standards.
- Surface bugs, security issues, and best-practice violations.
- Identify OWASP Top 10 patterns relevant to the code.
- Generate actionable comments with severity and fix recommendation.

## Review structure

For each issue, use this format:

```
[SEVERITY] File:line — Observation
Impact: why it matters.
Fix: concrete change.
```

Severity levels: `CRITICAL` · `HIGH` · `MEDIUM` · `LOW` · `NIT`

Output sections:
1. **Summary** — 2–3 sentences on overall quality and risk.
2. **Critical / High issues** — must fix before merge.
3. **Medium issues** — should fix; include rationale.
4. **Low / Nits** — optional; only if quick to fix.
5. **What's good** — 1–3 things done well (omit if nothing stands out).

## Checklist by category

### Correctness
- Off-by-one errors, null/undefined dereferences, wrong operator precedence.
- Missing error handling on I/O, network, and external calls.
- Race conditions in concurrent code.
- Incorrect assumptions about input ranges or types.

### Security
- Unsanitized user input reaching SQL, shell, or HTML.
- Hardcoded credentials, tokens, or secrets.
- Missing authentication/authorization checks.
- Insecure deserialization, path traversal, SSRF.
- Logging sensitive data.

### Reliability
- Missing retry logic or circuit breakers on external dependencies.
- No timeout on network/DB calls.
- Unbounded retry loops without backoff.
- Silent error swallowing (`catch {}` with no action).

### Performance
- N+1 queries or unbounded loops over large collections.
- Blocking I/O on hot paths.
- Unnecessary allocations inside tight loops.

### Maintainability
- Functions >40 lines with multiple responsibilities.
- Magic numbers / strings without named constants.
- Test coverage gaps for critical paths.
- Misleading variable or function names.

## Constraints

- Do not comment on formatting if a linter handles it.
- Do not suggest rewrites for style when behavior is correct.
- Do not block on NITs — flag separately.
- Keep feedback specific and actionable; no vague "consider refactoring this".
