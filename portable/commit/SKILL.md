---
name: commit
description: Use when creating a git commit for intended changes with a concise subject line and safe staging behavior.
version: 0.3.0
portable: true
tags: [git, commit]
---

Create a local git commit for the intended changes only.

Generate a concise imperative subject line.
Stage only relevant files.
Commit locally only. Never push.

## Commit Format

With Jira ticket:
`PROJ-123: <summary>`

Without Jira ticket:
`<summary>`

Rules:
- Jira ticket is OPTIONAL. Use only when explicitly known.
- Subject is REQUIRED.
- Imperative voice only.
- Maximum 72 characters.
- No trailing period.

Examples:
- `fix token refresh race`
- `PROJ-123: add timeout to cb proxy client`

Avoid:
- `misc updates`
- `fix stuff`
- `changes`
- `updated files`

## Safety Rules

- Never commit unrelated changes.
- Never blindly use `git add .` or `git add -A`.
- Never amend commits unless explicitly requested.
- Never push.
- Never create empty commits unless explicitly requested.
- If merge conflicts exist, stop and ask the user.
- If staged and unstaged changes appear unrelated, ask before proceeding.

## Argument Parsing

Interpret caller input as follows:

File paths or globs:
- contain `/`, `.`, `*`, `?`, or `**`
- treat as files to stage

Short imperative phrases:
- treat as commit guidance or summary intent

Mixed input:
- separate files from commit guidance

Example:
`commit auth.py and fix token expiry`

Result:
- file: `auth.py`
- summary intent: `fix token expiry`

If commit intent is ambiguous, ask exactly one concise clarifying question.

Examples of ambiguity:
- unrelated modified areas
- feature + refactor mixed together
- unclear target files
- large staged + unstaged divergence

## Commit Quality

Good commit subjects:
- describe observable behavior changes
- stay specific
- avoid implementation noise
- use imperative voice

Prefer:
- `fix token refresh race`
- `remove stale hiera cache`
- `add retry for couchbase writes`

Avoid:
- `updates`
- `cleanup`
- `final changes`
- `working version`

## Commit Body

Commit bodies are OPTIONAL.

Add a body only when useful:
- behavior changes
- migrations
- operational risk
- non-obvious reasoning
- follow-up work

Avoid bodies for trivial changes.

Body format:
- short paragraphs
- concise language
- no excessive formatting

## Co-Authored-By Trailer

Always append a `Co-Authored-By` trailer for the current AI model.

Format:

`Co-Authored-By: <model-name> <noreply@<domain>>`

Guidelines:
- Use the specific model version when known.
- Strip provider prefixes from raw identifiers.
- Do not use generic names like `Claude` or `GPT`.
- If unknown, use:
  - model name = normalized identifier
  - domain = `unknown.ai`

Examples:
- `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
- `Co-Authored-By: GPT-5 Mini <noreply@openai.com>`

## Validation

Before committing:
- Check repo status.
- Review staged and unstaged changes.
- Detect partially staged files.
- Ensure staged files match commit intent.
- Ensure no merge conflicts exist.

Validate the subject:
- <= 72 chars
- imperative voice
- no trailing period

Automatically strip trailing periods.

## Workflow

1. Parse caller intent.
2. Inspect repo state using:
   - `git status`
   - `git diff`
   - optionally `git diff --staged`
3. Determine intended files.
4. Detect ambiguity or unrelated changes.
5. Generate commit subject.
6. Validate subject.
7. Stage only intended files.
8. Create commit.
9. Append `Co-Authored-By` trailer.

## Commit Execution

For multi-line commit messages:
- use a heredoc or commit message file
- never embed literal `\n` escape sequences

Example:

```bash
git commit -m "$(cat <<'EOF'
fix token refresh race

Refresh tokens before expiration during long-running requests.

Co-Authored-By: GPT-5 Mini <noreply@openai.com>
EOF
)"
