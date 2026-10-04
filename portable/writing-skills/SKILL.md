---
name: writing-skills
description: Use when creating a new skill or custom command, editing, consolidating, or retiring an existing one, reviewing a skill library for quality, or verifying a skill actually changes agent behavior before relying on it.
metadata:
  version: 0.3.1
  portable: true
  tags: [skills, commands, authoring, validation, maintenance, documentation, portable]
---

# Writing Skills

**Writing a skill is test-driven development applied to process documentation.** Run a pressure scenario without the skill (RED: watch the agent fail), write the minimal skill that fixes those failures (GREEN), then close the loopholes the agent finds (REFACTOR).

**Core principle:** if you never watched an agent fail without the skill, you don't know whether the skill teaches the right thing.

Supporting files in this directory:

| File                              | Read when                                                                  |
| --------------------------------- | -------------------------------------------------------------------------- |
| `testing-skills-with-subagents.md` | Running RED/GREEN/REFACTOR: pressure scenarios, rationalization tables     |
| `anthropic-best-practices.md`     | Anthropic's official skill-authoring guidance                              |
| `persuasion-principles.md`        | Making discipline skills resist rationalization                            |
| `reference/repo-checklist.md`     | Full authoring/validation/maintenance checklist for skills and commands   |
| `graphviz-conventions.dot`, `render-graphs.js` | Drawing or rendering a skill's flowcharts                     |

## What belongs in a skill

**Create one when** the technique wasn't obvious, you'd reuse it across projects, and it applies broadly.

**Don't** for one-off solutions, things well-documented elsewhere, project-specific conventions (put those in the project's `CLAUDE.md`/`AGENTS.md`), or mechanical rules a validator or linter can enforce.

Skill types: **technique** (steps to follow), **pattern** (way of thinking), **reference** (API/tool docs). A skill is never a narrative of how you solved something once.

**Before creating, check for overlap.** If an existing skill covers ≥50% of the trigger space, extend it instead. When two skills overlap heavily, merge them into one canonical skill and move format- or project-specific detail into a supporting file.

## SKILL.md structure

- `name`: kebab-case, matches the directory, ≤64 chars.
- `description`: triggers only, ≤1024 chars (aim <500).

```markdown
---
name: skill-name
description: Use when ...
metadata:
  version: 0.1.0
  portable: true
  tags: [tag1, tag2]
---

# Skill Name

Core principle in 1–2 sentences.

## When to use / not use
## Core pattern or workflow
## Quick reference
## Common mistakes
```

Standard top-level frontmatter keys (agentskills.io): `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Everything else (`version`, `portable`, `tags`, `applies_to`) goes under `metadata:`.

Inline principles and code under ~50 lines. Move heavy reference (100+ lines) and reusable scripts into separate files, and tell the reader **when** to load each one.

## Descriptions decide discovery

The agent reads only `description` when choosing which skill to load.

- Start with "Use when…" and list concrete triggers: situations, symptoms, error text, tool and file names, synonyms.
- **Never summarize the workflow.** When a description says what the skill does step by step, agents follow the description and skip the body. Tested: "code review between tasks" caused one review where the body required two.
- Describe the situation, not yourself: "Use when tests are flaky", never "I can help with flaky tests". Technology-specific only if the skill is.

```yaml
# Bad: workflow summary the agent will follow instead of reading the body
description: Use for TDD - write test first, watch it fail, write minimal code, refactor
# Bad: vague
description: For async testing
# Good: triggers only
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

## Token efficiency

Frequently-loaded skills cost tokens in every session.

- Targets: <200 words for always-loaded skills, <500 words for most others. Check with `wc -w SKILL.md`.
- Point to `--help` instead of documenting every flag.
- Cross-reference other skills by name instead of repeating them. Mark hard dependencies: `**REQUIRED:** use <skill-name>`. Avoid `@file` syntax, which eager-loads.
- One excellent, runnable example beats several mediocre ones or the same example in five languages.

## Flowcharts

Only for non-obvious decisions, loops where the agent might stop early, or "A vs B" choices. Never for reference material, code, or linear steps. Use semantic node labels, not `step1`/`helper2`. See `graphviz-conventions.dot`.

## The iron law

```text
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to new skills **and to edits**: new sections, rewrites, merges, and consolidations included.

**No exceptions:**

- Not for "simple additions" or "just adding a section".
- Not for "documentation updates" or "it's only a reference".
- Don't keep untested changes as "reference"; don't adapt the skill while running tests.
- Write the skill before testing it? Delete it and start over.

**Violating the letter of the rule is violating the spirit of the rule.** The only changes that skip testing are ones that cannot change behavior: typo fixes, broken-link fixes, and version/metadata bumps.

| Skill type           | Test with                                         | Passes when                            |
| -------------------- | ------------------------------------------------- | -------------------------------------- |
| Discipline-enforcing | Combined pressures: time, sunk cost, exhaustion   | Agent follows the rule under pressure  |
| Technique            | Application to a new case and variations          | Agent applies it correctly             |
| Pattern              | Recognition plus counter-examples                 | Agent knows when and when not to apply |
| Reference            | Retrieval across common use cases                 | Agent finds and uses the right entry   |

"It's obviously clear", "it's just a reference", and "I'll test if problems show up" all mean the same thing: test it first.

For discipline skills, record the agent's exact rationalizations from RED, then counter each one explicitly: forbid the specific workaround, add it to a rationalization table, and list it under "Red flags". Details: `testing-skills-with-subagents.md`.

## This repository's conventions

1. **Layout**: `portable/<name>/` (cross-harness) or `runtime-specific/<runtime>/<name>/`. Each has `SKILL.md` + `manifest.json`; optional `reference/`, `scripts/`, `examples/`.
2. **Metadata parity**: `name`, `description`, `version`, `portable`, `tags` must match between SKILL.md frontmatter and `manifest.json` (`validate-skills.sh` enforces all five). Bump both together (patch: fixes; minor: additions; major: breaking workflow change).
3. **Pi-safe first**: portable bodies stay tool-agnostic. Label harness-specific calls clearly or move them to a runtime overlay.
4. **Gating**: `personal_machine_only` / `local_overlay_only` live in `manifest.json` and are independent of `portable`. Personal-only skills need a `## Personal Machine Activation` section.
5. **No orphans**: when merging or retiring a skill, delete its directory, update every cross-reference (`grep -rn <old-name>`), and note the replacement in the commit/PR so consumers can update.
6. **Scripts**: `#!/usr/bin/env bash`, `set -euo pipefail`, `--help`, `--dry-run` for anything mutating, shellcheck-clean.

```bash
./hacks/new-skill.sh my-skill                   # scaffold (add --runtime <name> for overlays)
./hacks/validate-skills.sh                      # metadata parity, adapters, frontmatter
python3 ./hacks/generate-skills-index.py        # regenerate INDEX.md + registry.json (never hand-edit)
git ls-files '*.sh' | xargs -r shellcheck --severity=error
```

## Checklist

**RED**
- [ ] Pressure scenarios written (3+ combined pressures for discipline skills)
- [ ] Baseline run without the skill; failures and rationalizations recorded verbatim

**GREEN**
- [ ] No existing skill already covers this
- [ ] Frontmatter valid; description is triggers-only, situation-focused, keyword-rich
- [ ] Body addresses the specific baseline failures, nothing speculative
- [ ] Every code snippet runs as written; one example per pattern; heavy material split into files with load conditions
- [ ] Scenarios re-run with the skill; agent complies

**REFACTOR**
- [ ] New rationalizations countered; re-tested until stable

**Ship**
- [ ] `validate-skills.sh` passes; index regenerated; diff contains only intended files
