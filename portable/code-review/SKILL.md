---
name: code-review
description: Use when reviewing code changes, a PR, or a commit and need structured, severity-graded findings covering correctness, security, reliability, and maintainability.
metadata:
  version: 0.3.0
  portable: true
  tags: [review, quality, security, portable]
---

# Code Review

Structured review focused on bugs, risk, and actionable improvements — not style opinions.

## Use when

- Reviewing a PR, commit, or diff for merge readiness.
- You need severity-ranked findings with concrete fixes.
- You want a reliability/security pass, not just style feedback.

## When not to use

- You only need formatting/lint cleanup.
- You are doing a broad architecture or roadmap critique.
- You need implementation planning rather than review findings.

## Related Skills

- `github-pr-review` for end-to-end PR review workflows.
- `github` for fetching PR context, checks, and CI data via `gh`.
- `communication-style` for concise review writeups with low friction.
- Language standards to apply alongside the checklist: `python`, `go-standards`, `mobile-android-design` (Compose UI).
- `deep-audit` for whole-codebase health; `improve-codebase-architecture` for structural refactoring candidates.

## Review structure

For each issue, use this format:

```text
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

## Steps

1. Identify the target (diff, PR, file, or directory to review).
2. Read the surrounding code, not just the diff: callers, tests, and config the change depends on.
3. Detect languages from file extensions and load the matching language skill if one exists.
4. Apply the checklist by category in order: Correctness → Security → Reliability → Performance → Maintainability.
5. Verify each finding before reporting: trace the failing input or path. Drop anything you can't substantiate.
6. Format each finding as `[SEVERITY] File:line — Observation`.
7. Present findings inline, or write to a review file if requested.
8. End with completion markers.

## Completion Markers

Every review MUST end with:

```text
✓ REVIEW_COMPLETE: {target} ({file_count} files, {line_count} lines)
✓ SECURITY: {Critical/High/Medium/Low/None}
✓ QUALITY: {critical_count} critical, {improvements_count} improvements
```

## Checklist

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
- Functions >50 lines with multiple responsibilities.
- Magic numbers / strings without named constants.
- Test coverage gaps for critical paths.
- Misleading variable or function names.

## Constraints

- Do not comment on formatting if a linter handles it.
- Do not suggest rewrites for style when behavior is correct.
- Do not block on NITs — flag separately.
- Keep feedback specific and actionable; no vague "consider refactoring this".

