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
- Optimize portable skills for Pi first, then OpenCode; if behavior differs, preserve Pi-safe guidance and move extra OpenCode-specific behavior into adapters or runtime-specific overlays.
- Follow `AUTHORING.md` for metadata and compatibility conventions.

## Validation & Scaffolding

### Validate Skills

Check all skills in `skills/` for required files, metadata completeness, and JSON validity:

```bash
./hacks/validate-skills.sh
```

### Regenerate Skills Index

`skills/INDEX.md` and `skills/registry.json` are generated from `skills/**/manifest.json` and `SKILL.md` frontmatter:

```bash
python3 ./hacks/generate-skills-index.py
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
./hacks/new-skill.sh my-skill-name
```

**Runtime-specific skill** (OpenCode, Claude, Pi, etc.):

```bash
./hacks/new-skill.sh my-skill-name --runtime opencode
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

By default it syncs links for OpenCode, Claude, and Pi:

- OpenCode: `~/.config/opencode/skills/portable` and `~/.config/opencode/skills/runtime`
- Claude: `~/.claude/skills/portable`
- Pi: consumes shared portable skills from `~/.agents/skills/`; `~/.pi/agent/skills/` available for Pi-local overlays

The sync script focuses on runtimes that need explicit materialized links. Pi normally reads the shared skill directory directly.

### Pi discovery order (important)

For Pi, prefer this model:

1. Shared portable skills from `~/.agents/skills/`
2. Pi-local overlays from `~/.pi/agent/skills/` only when needed

Treat `~/.pi/agent/skills/portable` as optional compatibility materialization, not a required baseline.

### Overlap policy for skills

When two skills overlap heavily:

- Keep one canonical skill as the primary target for discovery.
- Keep the other only if it serves as a compatibility alias for existing prompts.
- Add a short cross-reference in both skills so routing is deterministic.

Personal-machine-only opt-in:

- Skills with `"personal_machine_only": true` in `manifest.json` are skipped by default.
- To enable locally, add the skill name to `~/.personal-machine-skills.txt`.
- Personal-only skills must document activation in `SKILL.md` under a `## Personal Machine Activation` section, including allowlist setup and the `~/.personal-machine-skills.txt` path.
- Example:

```txt
grenadianbuzz-api
```

- Override allowlist path with `SKILL_PERSONAL_ALLOWLIST_FILE=/path/to/file`.

Local-overlay-only opt-in:

- Skills with `"local_overlay_only": true` in `manifest.json` are skipped unless a local local-overlay flag exists.
- Default flag path: `~/.dotfiles.local/overlays/local/.enabled`
- Override flag path with `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

Target a runtime explicitly:

```bash
./hacks/sync-skill-runtime-links.sh --runtime opencode
./hacks/sync-skill-runtime-links.sh --runtime claude
./hacks/sync-skill-runtime-links.sh --runtime pi
```
