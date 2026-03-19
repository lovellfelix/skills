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
