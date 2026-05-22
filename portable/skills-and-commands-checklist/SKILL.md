---
name: skills-and-commands-checklist
description: Use when authoring or maintaining portable skills and custom commands to ensure correctness, discoverability, and long-term maintainability across tools and machines.
metadata:
  version: "1.3.0"
  portable: true
  tags: [authoring, skills, commands, quality, portability, validation, maintenance]
---

# Skills and Commands Best-Practices Checklist

Covers both **portable skills** (SKILL.md + manifest.json) and **custom commands** (shell scripts, utilities, automation). Apply sections selectively based on artifact type.

## 10 Key Rules

1. **Metadata must match** — SKILL.md frontmatter = manifest.json for name, description, version, tags, and portability metadata (portable/license/compatibility when present)
2. **Describe the trigger** — `description:` starts with "Use when..." for agent discovery
3. **Ground in source truth** — one canonical SKILL.md or script; all symlinks resolve to it
4. **Test examples** — every code snippet must work as written
5. **Check links quarterly** — prevent stale references and broken documentation
6. **Mark personal-only clearly** — if `personal_machine_only: true`, add activation section to SKILL.md
7. **Validate before commit** — run `validate-skills.sh` and `shellcheck` on scripts
8. **Update registry after changes** — run `generate-skills-index.py` to keep INDEX.md and registry.json fresh
9. **Version semantically** — patch for fixes, minor for additions, major for breaking changes
10. **Prevent orphans** — remove skills/commands completely or flag as deprecated; no dead symlinks

## Quick Start

```bash
# New skill
./hacks/new-skill.sh my-skill-name
# edit SKILL.md + manifest.json
./hacks/validate-skills.sh
python3 ./hacks/generate-skills-index.py

# New command
touch hacks/my-command.sh
chmod +x hacks/my-command.sh
# add shebang + set -euo pipefail
shellcheck hacks/my-command.sh
```

## Artifact structure

**Portable skill:**

```text
skills/portable/my-skill/
├── SKILL.md          # required; frontmatter follows agentskills.io spec
├── manifest.json     # required; shared fields must match SKILL.md
├── examples/         # optional
├── reference/        # optional (heavy reference material)
└── scripts/          # optional
```

**Frontmatter (agentskills.io spec):**

Only these top-level keys are part of the standard: `name`, `description`,
`license`, `compatibility`, `metadata`, `allowed-tools`. Anything else
(version, portable, tags, applies_to, author, source, …) goes under the
`metadata:` map for cross-tool portability.

```yaml
name: my-skill # kebab-case, matches dir name, ≤64 chars
description: Use when… # trigger conditions only, ≤1024 chars
license: MIT # optional, only if applicable
metadata:
  version: "0.1.0"
  portable: true # false for personal/local-overlay-only
  tags: [tag1, tag2]
```

The local validator and registry generator read both top-level and
`metadata:`-nested values, so name/description/version/portable/tags
(and relevant portability fields such as license/compatibility) should
stay consistent with `manifest.json`.

## Version bumps

| Change                     | Bump                  |
| -------------------------- | --------------------- |
| Typos, link fixes, clarity | PATCH (0.1.0 → 0.1.1) |
| New sections, new examples | MINOR (0.1.0 → 0.2.0) |
| Breaking workflow change   | MAJOR (0.1.0 → 1.0.0) |

Update version in **both** SKILL.md and manifest.json simultaneously.

## Post-edit validation sequence

1. Run `./hacks/validate-skills.sh`.
2. If tags/description/metadata changed, run `python3 ./hacks/generate-skills-index.py`.
3. Review `git diff` to confirm only intended skill, manifest, and required generated registry/index outputs changed.

## Full checklist

All 10 phases (authoring, portability, validation, registry, discoverability, maintenance, mistakes, submission, quick-start, artifact anatomy) → `reference/full-checklist.md`

## See Also

- `hacks/validate-skills.sh` — metadata + adapter health
- `hacks/generate-skills-index.py` — rebuild registry
- `skills/INDEX.md` — catalog of all portable skills
- `docs/skill-spec/SKILL-SPEC.md` — technical skill format spec
