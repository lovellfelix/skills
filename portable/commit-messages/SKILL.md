---
name: commit-messages
description: Use when writing a git commit message, to keep it terse and human instead of reading like AI output — no restated diffs, no filler trailers, no essay-length bodies.
metadata:
  version: 0.2.0
  portable: true
  tags: [git, commits, style, workflow, portable]
---

# Commit Messages

The subject line does the work. Add a body only when the "why" isn't obvious from the subject or the diff itself.

Based on [cbea.ms/git-commit](https://cbea.ms/git-commit/) and [tbaggery's note on commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) — the two canonical references for this. No `type(scope):` prefix — that's Conventional Commits, a different (and not preferred) convention.

## Format

- Capitalized, imperative subject line: "Fix bug" not "fixed bug" or "fixes bug." Test: it should complete "If applied, this commit will _______."
- Target ~50 characters for the subject; 72 is the hard ceiling. No trailing period.
- Blank line between subject and body — always, even for a one-line body.
- Body, if needed: wrap at ~72 chars. Explains what and why, not how — the diff already shows how.
- Reference an issue/PR number when one exists, either inline in the subject (`... (#123)`) or on its own trailer line (`Resolves: #123`) — match whatever the repo already does.

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
Fix sensitive-file-guard.sh never firing on Bash (#141)

The guard only hooked Read/Edit/Write. Bash could still cat/write a
gitignored secret file straight through. Added the same path check
to the Bash pre-tool hook.
```

```
Tell tool-agent.sh's remote LLM never to dump credential files (#142)
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

Rewritten to the same information, without the essay or the type/scope prefix:

```
Stop enforcing the retired personal-skill allowlist

validate-skills.sh still required allowlist docs from a model that was
replaced months ago by flag-only gating (AUTHORING.md already reflects
this). Fixed the check and the 15 docs it forced to match.
```

## Workflow

1. `git log --oneline -10` in the repo before writing anything. If the repo has clearly and consistently standardized on a different convention (Conventional Commits, ticket-ID prefixes), match it rather than imposing this style on someone else's project — this skill describes the author's own preference, not a universal rule.
2. Draft the subject first, imperative mood, capitalized, as if finishing "This commit will...".
3. Only add a body if the subject can't carry the why. Once drafted, reread it and cut any line the diff already makes obvious.
4. No trailers unless asked for one on that specific commit.
