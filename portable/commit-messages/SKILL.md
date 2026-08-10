---
name: commit-messages
description: Use when writing a git commit message, to keep it terse and human instead of reading like AI output — no restated diffs, no filler trailers, no essay-length bodies.
metadata:
  version: 0.1.0
  portable: true
  tags: [git, commits, style, workflow, portable]
---

# Commit Messages

The subject line does the work. Add a body only when the "why" isn't obvious from the subject or the diff itself.

## Format

- `type(scope): imperative summary`, ≤72 chars, no trailing period.
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`.
- Reference an issue/PR number in the subject when one exists: `(#123)`.
- Body, if needed: 1–4 short lines, wrapped ~72 chars. States why it broke or why this approach — not what the diff already shows.

## Never

- No `Claude-Session:` / `Generated with Claude Code` / `Co-Authored-By: Claude` trailers, unless the user explicitly asks for one on that commit.
- No restating the diff ("Added a function that does X", "Modified Y to include Z") — the diff already says that.
- No `Summary:` / `Changes:` / `Testing:` headers — that structure belongs in a PR body, not a commit.
- No hedge words or marketing adjectives: comprehensive, robust, seamless, powerful, extensive.
- No emoji.
- No multi-paragraph justification. One tight paragraph, or a short list of facts — never both.

## Good vs. bad

Good (terse, specific, matches how most repos actually write history):

```
fix(claude): sensitive-file-guard.sh never fired on Bash, only Read/Edit/Write (#141)
feat(jarvis): tell tool-agent.sh's remote LLM never to dump credential files (#142)
```

Bad — reads as AI output, avoid this shape:

```
fix(skills): stop documenting/enforcing the retired allowlist model

AUTHORING.md already reflects the real design: personal_machine_only
skills link automatically off the ~/.overlay/local/.enabled flag alone,
no per-skill allowlist -- a deliberate change from months ago (removed
because a missing entry silently skipped a skill on every bootstrap
run). validate-skills.sh (added this session, ported from the old
dotfiles-side script) still enforced the abandoned allowlist model in
every skill's '## Personal Machine Activation' section...
```

Rewritten to the same information, without the essay:

```
fix(skills): stop enforcing the retired personal-skill allowlist

validate-skills.sh still required allowlist docs from a model that was
replaced months ago by flag-only gating (AUTHORING.md already reflects
this). Fixed the check and the 15 docs it forced to match.
```

## Workflow

1. `git log --oneline -10` in the repo before writing anything — match its existing tone and format, don't impose a house style it doesn't use.
2. Draft the subject first, imperative mood, as if finishing "This commit will...".
3. Only add a body if the subject can't carry the why. Once drafted, reread it and cut any line the diff already makes obvious.
4. No trailers unless asked for one on that specific commit.
