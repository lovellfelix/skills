# Skills Authoring Guide

Practical conventions for adding or updating skills in this repository.

## Required Files

Each skill directory must include:

- `SKILL.md`
- `manifest.json`

Optional support directories:

- `examples/`
- `reference/`
- `scripts/`

## Required Metadata

`SKILL.md` frontmatter must include:

```yaml
---
name: my-skill
description: One-line purpose statement.
version: 0.1.0
portable: true
tags: [workflow, example]
---
```

`manifest.json` must include matching shared fields and adapters:

```json
{
  "schema_version": "1.0",
  "name": "my-skill",
  "version": "0.1.0",
  "portable": true,
  "entrypoint": "SKILL.md",
  "tags": ["workflow", "example"],
  "adapters": {
    "opencode": {
      "path": "SKILL.md",
      "mode": "native"
    },
    "cursor": {
      "path": "SKILL.md",
      "mode": "import"
    },
    "claude": {
      "path": "SKILL.md",
      "mode": "include"
    },
    "copilot": {
      "path": "SKILL.md",
      "mode": "include"
    },
    "forge": {
      "path": "SKILL.md",
      "mode": "include"
    }
  },
  "compatibility": {
    "runtimes": {
      "opencode": {
        "min_version": "*"
      },
      "cursor": {
        "min_version": "*"
      },
      "claude": {
        "min_version": "*"
      },
      "copilot": {
        "min_version": "*"
      },
      "forge": {
        "min_version": "*"
      }
    }
  }
}
```

Compatibility rules:

- `compatibility.runtimes` is required.
- Runtime keys must match `adapters` keys.
- All five runtimes (`opencode`, `cursor`, `claude`, `copilot`, `forge`) should be declared for portable skills.
- `min_version` can be `*` or a runtime-version constraint string.

Optional activation metadata:

- `personal_machine_only`: boolean (manifest-only, default `false`)
- When `true`, runtime link sync only enables the skill when the local allowlist includes the skill name.
- Local allowlist path: `~/.personal-machine-skills.txt` (one skill name per line)
- Validation requirement: when `personal_machine_only` is `true`, `SKILL.md` must include a `## Personal Machine Activation` section that explains allowlist setup and references `~/.personal-machine-skills.txt`.
- `work_machine_only`: boolean (manifest-only, default `false`)
- When `true`, runtime link sync only enables the skill when the local work-machine flag file exists.
- Default flag path: `~/.work-env-skills`
- Override flag path: `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`
- Validation requirement: when `work_machine_only` is `true`, `SKILL.md` must include a `## Work Machine Activation` section that references `~/.work-env-skills`.

## Versioning

- Use semantic versioning in `version`.
- Bump patch for fixes, minor for additive updates, major for breaking workflow changes.
- Keep `SKILL.md` and `manifest.json` versions in sync.

## Runtime Link Health

- Every `adapters.<runtime>.path` must point to an existing file in the same skill directory.
- Use adapter modes from: `native`, `import`, `include`.

## Generation Flow

Regenerate generated artifacts after skill edits:

```bash
python3 ./hacks/generate-skills-index.py
```

This updates:

- `skills/INDEX.md`
- `skills/registry.json`

## Validation Flow

Run validation before commit:

```bash
./hacks/validate-skills.sh
```

Checks include metadata completeness, shared-field consistency, adapter link health, compatibility coverage, and personal-machine activation guidance for personal-only skills.

## Scaffold a New Skill

Portable:

```bash
./hacks/new-skill.sh my-skill-name
```

Runtime-specific:

```bash
./hacks/new-skill.sh my-skill-name --runtime opencode
```
