---
name: commit
description: Use when making a git commit and need a correctly formatted subject line with optional Jira ticket and Co-Authored-By trailer.
version: 0.2.0
portable: true
tags: [git, commit, conventional-commits, portable]
---

Create a git commit for the current changes using a short, imperative subject line.

## Format

With Jira ticket: `<JIRA-TICKET>: <summary>`
Without Jira ticket: `<summary>`

- `JIRA-TICKET` OPTIONAL. Use when the ticket is known (e.g. `PROJ-123`). Omit if unknown — do not guess.
- `summary` REQUIRED. Short, imperative, <= 72 chars, no trailing period.

## Notes

- Body is OPTIONAL. If needed, add a blank line after the subject and write short paragraphs.
- **Always use a heredoc** for multi-line messages — never pass `\n` escape sequences in `-m` strings, they render as literal backslash-n.
- A blank line is **required** between the body (or subject) and the `Co-Authored-By` trailer; without it git does not treat it as a trailer.
- Do NOT include `BREAKING CHANGE`, `Change-Type`, or other change-type footers.
- Do NOT add sign-offs (no `Signed-off-by`).
- Do not use provider-only trailers like "Claude"; include the specific model name (e.g., Claude Sonnet 4.5).
- Only commit; do NOT push.

## Argument Parsing

Treat caller-provided arguments as follows:
- Strings containing `/`, `.`, or glob characters (`*`, `?`, `**`) → treat as file paths/globs to stage.
- Short imperative phrases → treat as commit summary or body guidance.
- Mixed input (e.g. "commit auth.py and fix token expiry") → split: file = `auth.py`, summary = "fix token expiry".
- If ambiguous, ask one clarifying question before proceeding.

## Validation (run before committing)

- Subject must be <= 72 chars. If longer, truncate or ask the user to shorten.
- Subject must not end with a period — strip trailing periods automatically.
- Subject should be imperative voice (e.g. "add", "fix", "remove"). If not, reword before committing.

## Co-Authored-By Trailer

Always append a `Co-Authored-By` git trailer identifying the AI model that authored the commit.

### How to determine your model name

**Step 1 — Get the raw identifier.** Your model identifier is provided in your system prompt or session context. Use it exactly as given.

**Step 2 — Strip any provider prefix.** Remove everything up to and including the last `/` (e.g., `github-copilot/claude-sonnet-4.6` → `claude-sonnet-4.6`). Provider prefixes like `github-copilot/`, `anthropic/`, `openai/` are never part of the model name.

**Step 3 — Match against the table below (first match wins, top to bottom).** Patterns are applied to the normalized identifier from Step 2.

> **Do NOT guess or use a generic name like "Claude" — always include the specific version from the table.**

| Model identifier pattern (after prefix strip) | Human-readable name | Email domain |
|------------------------------------------------|--------------------:|--------------|
| `claude-sonnet-4-5*` | Claude Sonnet 4.5 | anthropic.com |
| `claude-sonnet-4.5*` | Claude Sonnet 4.5 | anthropic.com |
| `claude-sonnet-4-7*` | Claude Sonnet 4.7 | anthropic.com |
| `claude-sonnet-4.7*` | Claude Sonnet 4.7 | anthropic.com |
| `claude-sonnet-4-6*` | Claude Sonnet 4.6 | anthropic.com |
| `claude-sonnet-4.6*` | Claude Sonnet 4.6 | anthropic.com |
| `claude-sonnet-4*` | Claude Sonnet 4 | anthropic.com |
| `claude-haiku-4-5*` | Claude Haiku 4.5 | anthropic.com |
| `claude-haiku-4.5*` | Claude Haiku 4.5 | anthropic.com |
| `claude-haiku-*` | Claude Haiku | anthropic.com |
| `claude-opus-4*` | Claude Opus 4 | anthropic.com |
| `claude-opus-*` | Claude Opus | anthropic.com |
| `gpt-5.4-mini*` | GPT-5.4 Mini | openai.com |
| `gpt-5.4*` | GPT-5.4 | openai.com |
| `gpt-5.3-codex*` | GPT-5.3 Codex | openai.com |
| `gpt-5.1-codex*` | GPT-5.1 Codex | openai.com |
| `gpt-5-mini*` | GPT-5 Mini | openai.com |
| `gpt-4.1*` | GPT-4.1 | openai.com |
| `gpt-4o*` | GPT-4o | openai.com |
| `o4-mini*` | o4-mini | openai.com |
| `o3*` | o3 | openai.com |
| `gemini-*` | Gemini | google.com |

**If no pattern matches:** use the normalized identifier (after prefix strip) as the model name, with `noreply@unknown.ai` as the domain.

Format: `Co-Authored-By: <human-readable name> <noreply@<domain>>`

### Pattern matching rules

- **First match wins.** Apply patterns top-to-bottom and stop at the first match.
- **`*` means zero or more characters.** `gpt-5.4-mini*` matches `gpt-5.4-mini` and `gpt-5.4-mini-2025-07-01`.
- **`gpt-5.4-mini*` MUST be checked before `gpt-5.4*`** — they are ordered correctly in the table above.
- **`claude-sonnet-4-5*` MUST be checked before `claude-sonnet-4*`** — they are ordered correctly in the table above.

## Steps

1. Parse the caller's arguments: separate file paths/globs from commit guidance (see Argument Parsing above).
2. Run `git status` and `git diff` to understand the current changes (limit to argument-specified files if provided).
3. (Optional) Run `git log -n 20 --pretty=format:%s` to check commonly used subject patterns.
4. If ambiguous extra files are staged or unstaged, ask the user which to include before proceeding.
5. Validate the subject (length <= 72, no trailing period, imperative voice).
6. Stage only the intended files (`git add <paths>` or `git add -A` if no files specified).
7. Determine your model name using the steps above.
8. Run `git commit` using a heredoc:

```bash
# With Jira ticket:
git commit -m "$(cat <<'EOF'
PROJ-123: <summary>

[optional body]

Co-Authored-By: <model-name> <noreply@<domain>>
EOF
)"

# Without Jira ticket:
git commit -m "$(cat <<'EOF'
<summary>

[optional body]

Co-Authored-By: <model-name> <noreply@<domain>>
EOF
)"
```
