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
    "claude": {
      "path": "SKILL.md",
      "mode": "include"
    }
  },
  "compatibility": {
    "runtimes": {
      "opencode": {
        "min_version": "*"
      },
      "claude": {
        "min_version": "*"
      },
      "pi": {
        "min_version": "*"
      }
    }
  }
}
```

Compatibility rules:

- `compatibility.runtimes` is required.
- Runtime keys must match `adapters` keys.
- All supported runtimes (`opencode`, `claude`, `pi`) should be declared for portable skills.
- Pi currently consumes portable skills through shared discovery (`~/.agents/skills/`) and does not require a dedicated `pi` adapter key in `manifest.json`.
- Write portable skill bodies to be Pi-safe first: tool-agnostic, concise, and compatible with progressive discovery. If you need OpenCode-only examples or tool calls, label them clearly or move them into runtime-specific overlays.
- `min_version` can be `*` or a runtime-version constraint string.

Optional activation metadata (symmetric flag-file model):

- `personal_machine_only`: boolean (manifest-only, default `false`)
  - When `true`, the skill is linked only on personal machines (i.e., when `~/.dotfiles.local/overlays/local/.enabled` is **absent**).
  - Use for skills that are irrelevant or inappropriate on local-overlay machines (personal projects, life admin, homelab, personal dev stacks).
  - No allowlist or per-machine opt-in required — the environment signal alone determines linking.
- `local_overlay_only`: boolean (manifest-only, default `false`)
  - When `true`, the skill is linked only on machines where `~/.dotfiles.local/overlays/local/.enabled` is **present**.
  - Use for skills that are local-overlay specific (private tooling, internal workflows, local-overlay MCP surfaces).
- Both flags share the same gate file: `~/.dotfiles.local/overlays/local/.enabled`
  - Present → local-overlay machine: `local_overlay_only` skills link, `personal_machine_only` skills skip.
  - Absent → personal machine: `personal_machine_only` skills link, `local_overlay_only` skills skip.
  - Override for testing: `SKILL_WORK_MACHINE_FLAG_FILE=/dev/null` (personal) or `SKILL_WORK_MACHINE_FLAG_FILE=~/.dotfiles.local/overlays/local/.enabled` (work).
- Skills with neither flag link on all machines (universal portable skills).

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
