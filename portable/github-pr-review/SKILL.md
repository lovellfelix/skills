---
name: github-pr-review
description: Deterministic, GitHub-integrated PR review skill tuned for SRE/infra changes. Fetches PR metadata, diff, CI status, applies type-specific checklists, formats deterministic findings, and can post reviews via gh.
version: 0.2.0
portable: true
tags: [review, github, pr, sre, portable]
---

# GitHub PR Review (portable)

Deterministic end-to-end PR review focused on infrastructure, configuration, and SRE concerns. Produce the same structured output for the same PR every run; grade consistently and include actionable fixes suitable for posting as GH review comments.

## Trigger

Use this skill when you need a full, reproducible review of a GitHub PR (pre- or post-submission) with SRE-aware checklists and the option to post findings via the gh CLI.

## Inputs

- PR URL (https://github.com/owner/repo/pull/123)
- Or `#<number>` when invoked from the repository root

## Deterministic Steps (must run in this exact order)

### Step 1 — Auth check

```bash
gh auth status
```

Abort and surface the auth error if this fails.

### Step 2 — Fetch PR metadata, diff, and CI status

```bash
# Fetch PR metadata (explicit field list — do not add extras)
gh pr view <PR> --json number,title,body,author,headRefName,baseRefName,commits,changedFiles,additions,deletions,mergeable,comments,files

# Capture the full diff
gh pr diff <PR> > pr.diff
wc -l pr.diff   # record total line count for completion markers

# CI status — enumerate all check runs; never hardcode workflow name
gh pr checks <PR> --json name,status,conclusion,startedAt,completedAt
```

`pr.diff` line count (`wc -l` output) is the canonical value for `{line_count}` in the completion markers. Record it now.

### Step 3 — Classify PR type (deterministic rules, first match wins)

Apply rules top-to-bottom. Stop at the first rule that matches.

1. **Infrastructure/K8s** — if `apiVersion:` or `kind:` appears in any changed file, OR any changed path starts with `k8s/`, `charts/`, `helm/`, or `manifests/`.
2. **Config/YAML** — if ≥ 50% of changed files have extension `.yaml` or `.yml`.
3. **Shell/Automation** — if ≥ 50% of changed files have extension `.sh`, `.bash`, or `.zsh`.
4. **Code** — if ≥ 50% of changed files have extension `.py`, `.java`, `.ts`, `.js`, `.go`, `.kt`, `.rb`, `.rs`, or `.cpp`.
5. **Docs** — if ≥ 50% of changed files are in `docs/` or have extension `.md` or `.rst`.
6. **Mixed** — apply all checklists whose threshold reaches ≥ 25% of changed files.

**Tiebreaker:** when two types would each reach exactly 50%, Infrastructure/K8s > Config/YAML > Code > Shell > Docs. Record the resolved type in the output header.

### Step 4 — Apply the type-specific checklist

Note: For generic code correctness/security/reliability checks reference the portable `code-review` skill. Do not duplicate its full checklist here — invoke it for deep code analysis when the PR is primarily Code type.

#### Config / YAML

- Drift potential: does this restore or override cluster-wide defaults? How will it interact with existing operator state?
- Required-field correctness: required keys present; parse-don't-validate pattern (use explicit types, not permissive parsing)
- Env-specific correctness: secrets vs configmap separation, no production creds in non-prod files
- Confetti / linter compliance: run confetti-validate or repo linter and include results
- Impact scope: which environments/namespaces are targeted?

#### Infrastructure / Kubernetes

- Blast radius: estimate number of pods/nodes affected (count resources, selectors, namespaces)
- Rollback safety: are previous manifests retained or reversible? Is a fast rollback path available?
- Resource correctness: CPU/memory limits/requests set and sane for the service tier
- Health checks: readiness/liveness probes added or changed; verify intervals and timeouts
- Namespace / RBAC: review any new ClusterRole/ClusterRoleBinding for overly-broad permissions
- Migration effects: storage migrations, schema changes, and any controller/operator assumptions

#### Code (Python / Java / other)

- Apply the `code-review` skill for correctness/security/reliability items.
- Prefer explicit types, parse-don't-validate, and no silent error swallowing (no empty except/catch blocks)
- Tests: presence of unit/integration tests covering new behavior; deterministic expectations for SRE code
- Observability: new code emits metrics/traces/logs with useful labels; errors are instrumented

#### Shell / Automation

- Idempotency: safe to re-run without side-effects
- Exit handling: scripts use `set -euo pipefail` (or equivalent) and trap `ERR`/`EXIT` where appropriate
- No unbounded loops or blocking waits without timeouts
- Prod-safety guards: explicit confirmation, dry-run flags, and rate limits for mass actions

#### Docs

- Accuracy: examples and paths must reflect current repo layout and commands
- No stale links or wrong API/CLI flags
- Terminology consistent with repo conventions

### Step 5 — Format findings (canonical, deterministic)

Each finding MUST use this block exactly — no paraphrasing the format:

```text
[SEVERITY] file:line — Observation
Impact: why it matters
Fix: concrete change
```

**Ordering rules (applied deterministically):**
1. Group by severity: CRITICAL → HIGH → MEDIUM → LOW → NIT
2. Within each severity group: sort by file path lexicographically (ascending)
3. Within the same file: sort by line number ascending
4. Never reorder findings within a group for narrative flow

**Severity definitions (apply consistently):**
- CRITICAL — causes data loss, security breach, or service outage if merged
- HIGH — likely regression, correctness bug, or missing required safeguard
- MEDIUM — improvement strongly recommended; does not block but degrades quality/reliability
- LOW — optional improvement with small benefit
- NIT — style, naming, or trivial consistency fix

**Completion metrics:**
- `{file_count}` = number of unique files changed (from `changedFiles` field)
- `{line_count}` = `wc -l pr.diff` output recorded in Step 2
- `{security_level}` = highest security-relevant finding severity (CRITICAL/HIGH/MEDIUM/LOW/None)
- `{critical_count}` = count of CRITICAL findings
- `{improvements_count}` = count of HIGH + MEDIUM findings

### Step 6 — Post review (optional)

Default: output findings to stdout only. Only post to GitHub if the user explicitly requests it.

Post a neutral review comment (no merge decision):

```bash
gh pr review <PR> --comment -b "$(cat <<'EOF'
{review-body}
EOF
)"
```

Request changes (block merge until addressed):

```bash
gh pr review <PR> --request-changes -b "$(cat <<'EOF'
Blocking issues found — please address the HIGH/CRITICAL items.

{summary}
EOF
)"
```

Approve with comments:

```bash
gh pr review <PR> --approve -b "LGTM with minor nits: {short-list}"
```

Post an inline file/line comment using the GitHub API (use when diff position is exact):

```bash
gh api repos/:owner/:repo/pulls/<PR>/comments \
  -f body='...' \
  -f commit_id='<COMMIT_SHA>' \
  -f path='path/to/file.yaml' \
  -f position=<N>
```

Use the API form only when a finding maps to a specific diff line; otherwise use `gh pr review --comment` for the full review body.

## Deterministic output requirements

- Always list PR metadata at the top (number, title, type, author, base→head)
- Sort files and findings deterministically (lexicographic path, then line number within severity group)
- Always include the completion markers below — they are required by policy and used by automation

```
✓ REVIEW_COMPLETE: {pr-url} ({file_count} files, {line_count} lines)
✓ SECURITY: {High/Medium/Low/None}
✓ QUALITY: {critical_count} critical, {improvements_count} improvements
```

## Guidance on automation & safety

- Default to `--comment` (non-blocking) until at least one human confirms the change set.
- For high-blast-radius infra changes, include an explicit recommendation to hold the merge behind a canary rollout.
- When in doubt about permissions (ClusterRole/ClusterRoleBinding), recommend least-privilege change and call out owner teams.
- Never hardcode CI workflow names — always use `gh pr checks` to enumerate actual check runs.

## Example output header

```
## PR Review: #123 — Add redis cache layer
Type: Code (Python)
Author: alice | base: main ← head: feature/redis-cache
Files: 8 | Lines: 342 | CI: 3/3 passing

### CRITICAL (1)
...

### HIGH (2)
...

✓ REVIEW_COMPLETE: https://github.com/owner/repo/pull/123 (8 files, 342 lines)
✓ SECURITY: High
✓ QUALITY: 1 critical, 2 improvements
```

END
