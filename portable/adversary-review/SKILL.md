---
name: adversary-review
description: "Use when a plan, design doc, RFC, proposal, or incident analysis needs a genuine second opinion from a different model, not another self-review pass. Runs the content through hacks/adversary-review.sh (OpenCode Go, gpt-5.6-luna) from a chosen adversarial perspective. Not for code generation or implementation."
metadata:
  version: 0.1.0
  portable: true
  tags: [review, adversarial, critique, second-opinion, plan, rfc]
---

# Adversary Review

Get a critique from an independent model, not from re-reading your own output. Claude Code's
native subagents (`Agent` tool) can only run on Claude models — there is no way to spawn a
subagent on an opencode-go model directly. This skill shells out to
`hacks/adversary-review.sh`, which calls the OpenCode Go subscription's `gpt-5.6-luna` over
its Anthropic-native Messages API and returns a structured critique.

## When to use

- Before committing to a significant architectural approach or design.
- Before sharing a proposal, RFC, or incident postmortem externally.
- When you (Claude) have just written or endorsed a plan and want a check that isn't
  correlated with your own reasoning — a different model, not a second read-through.
- Not for code generation, implementation, or line-by-line code review (use `code-review` or
  `design-doc-review` for those).

## Steps

1. Identify the content to review (file path, or content already in context) and pick a
   perspective. Default to `"skeptical but fair domain expert"` if the user doesn't specify
   one. Useful perspectives: `"skeptical reader"`, `"competitor"`, `"executive"`,
   `"customer"`, `"security engineer"`.
2. Run the script, piping the content in or pointing at a file:

   ```bash
   cat <path-to-plan.md> | hacks/adversary-review.sh --perspective "security engineer"
   # or
   hacks/adversary-review.sh --file docs/adr/003-migration.md --perspective competitor
   ```

   If the content only exists in the current conversation (not yet written to a file), pass
   it as the trailing argument instead — quote it as a single shell argument.

3. Present the critique verbatim to the user — do not summarize away the Critical/Major
   findings or soften the Probing Questions. This is meant to be a real second opinion, not
   Claude's paraphrase of one.
4. If the script errors (missing `OPENCODE_GO_API_KEY`, curl failure, empty response), report
   the actual error — do not silently fall back to reviewing the content yourself and
   presenting that as the adversary's opinion.

## Constraints

- Do not edit or rewrite the content being reviewed as part of this skill.
- Do not pre-filter or soften the critique before showing it to the user.
- This is a genuinely different model from Claude — expect it to occasionally disagree with
  Claude's own prior analysis. That disagreement is the point; do not resolve it silently in
  Claude's favor.
