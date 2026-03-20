# Skills Directory

This directory is the canonical home for skills-first guidance in this repository.

## Purpose

- Keep reusable skill content in one root-level location.
- Keep skills portable across different runtimes.
- Separate portable skill logic from runtime-specific adapter details.

## Layout

- `portable/`
  - Tool-agnostic skill packages.
  - Each package should include `SKILL.md` and `manifest.json`.
- `runtime-specific/`
  - Runtime overlays or adapter files.
  - `runtime-specific/opencode/` is reserved for OpenCode-specific wiring.
- `reference/`
  - Shared references for migration and authoring standards.
- `archive/`
  - Deprecated or superseded skills kept for traceability.

## Conventions

- Prefer creating new skills under `portable/`.
- Keep `SKILL.md` concise and practical.
- Keep runtime-specific behavior out of portable skill cores.
- Follow `AUTHORING.md` for metadata and compatibility conventions.

## Validation & Scaffolding

### Validate Skills

Check all skills in `skills/` for required files, metadata completeness, and JSON validity:

```bash
./scripts/validate-skills.sh
```

### Regenerate Skills Index

`skills/INDEX.md` and `skills/registry.json` are generated from `skills/**/manifest.json` and `SKILL.md` frontmatter:

```bash
python3 ./scripts/generate-skills-index.py
```

CI runs this generator and fails if generated artifacts are out of date.

Validates:
- `SKILL.md` frontmatter (name, description, version, portable flag, tags)
- `manifest.json` structure, adapter definitions, and compatibility metadata
- Adapter path health (runtime link targets exist)
- Directory naming conventions
- Cross-references between files

### Create a New Skill

**Portable skill** (works across runtimes):

```bash
./scripts/new-skill.sh my-skill-name
```

**Runtime-specific skill** (OpenCode, Claude, Cursor, etc.):

```bash
./scripts/new-skill.sh my-skill-name --runtime opencode
```

Both generate scaffolding with:
- `SKILL.md` template with YAML frontmatter
- `manifest.json` with adapter mappings
- `examples/` and `reference/` directories (optional)

## Runtime Materialization

Canonical source remains in this repo:

- `skills/portable/` for portable skills
- `skills/runtime-specific/<runtime>/` for runtime overlays

Runtime-facing paths can be generated as symlinks using:

```bash
./hacks/sync-skill-runtime-links.sh
```

By default it syncs links for OpenCode, Claude, and Cursor (when detected):

- OpenCode: `~/.config/opencode/skills/portable` and `~/.config/opencode/skills/runtime`
- Claude: `~/.claude/skills/portable`
- Cursor: `~/.cursor/skills/portable`

Personal-machine-only opt-in:

- Skills with `"personal_machine_only": true` in `manifest.json` are skipped by default.
- To enable locally, add the skill name to `~/.config/opencode/personal-machine-skills.txt`.
- Example:

```txt
grenadianbuzz-api
```

- Override allowlist path with `SKILL_PERSONAL_ALLOWLIST_FILE=/path/to/file`.

Target a runtime explicitly:

```bash
./hacks/sync-skill-runtime-links.sh --runtime opencode
./hacks/sync-skill-runtime-links.sh --runtime claude
./hacks/sync-skill-runtime-links.sh --runtime cursor
```
