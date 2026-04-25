---
name: commit
description: Use when making a git commit and need a correctly formatted Conventional Commits subject line.
---

Create a git commit for the current changes using a concise Conventional Commits-style subject.

## Format

`<type>(<scope>): <summary>`

- `type` REQUIRED. Use `feat` for new features, `fix` for bug fixes. Other common types: `docs`, `refactor`, `chore`, `test`, `perf`.
- `scope` OPTIONAL. Short noun in parentheses for the affected area (e.g., `api`, `parser`, `ui`).
- `summary` REQUIRED. Short, imperative, <= 72 chars, no trailing period.

## Notes

- Body is OPTIONAL. If needed, add a blank line after the subject and write short paragraphs.
- Do NOT include breaking-change markers or change-type footers.
- Do NOT add sign-offs (no `Signed-off-by`).
- Only commit; do NOT push.
- If it is unclear whether a file should be included, ask the user which files to commit.
- Treat any caller-provided arguments as additional commit guidance. Common patterns:
  - Freeform instructions should influence scope, summary, and body.
  - File paths or globs should limit which files to commit. If files are specified, only stage/commit those unless the user explicitly asks otherwise.
  - If arguments combine files and instructions, honor both.

## Co-Authored-By Trailer

Always append a `Co-Authored-By` git trailer identifying the AI model that authored the commit. Use a blank line to separate it from the body (or subject if no body).

Format by provider:

- Claude (Anthropic): `Co-Authored-By: Claude <noreply@anthropic.com>`
- GPT / o-series (OpenAI): `Co-Authored-By: GPT-4.1 <noreply@openai.com>`
- Gemini (Google): `Co-Authored-By: Gemini <noreply@google.com>`
- Codex / GitHub Copilot: `Co-Authored-By: GitHub Copilot <noreply@github.com>`

Use your own model name in the trailer (e.g. `Claude Sonnet 4.6`, `GPT-4.1`, `o3`).

## Steps

1. Infer from the prompt if the user provided specific file paths/globs and/or additional instructions.
2. Review `git status` and `git diff` to understand the current changes (limit to argument-specified files if provided).
3. (Optional) Run `git log -n 50 --pretty=format:%s` to see commonly used scopes.
4. If there are ambiguous extra files, ask the user for clarification before committing.
5. Stage only the intended files (all changes if no files specified).
6. Run `git commit` using a heredoc to preserve the trailer newline:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <summary>

[optional body]

Co-Authored-By: <Model Name> <noreply@provider.com>
EOF
)"
```
