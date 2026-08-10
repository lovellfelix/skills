# skills — Project Instructions

Cross-harness skill library for Claude Code, OpenCode, and Pi. Extracted from `lovellfelix/dotfiles` on 2026-08-09 (see `lovellfelix/dotfiles`'s `docs/adr/005-agent-jarvis-skills-repo-split.md`). This repo owns skill _content_; runtime materialization into each harness (`~/.claude/skills/`, `~/.config/opencode/skills/`, `~/.pi/agent/skills/`) is a `dotfiles`-side concern (`hacks/sync-skill-runtime-links.sh`, reads from `SKILLS_ROOT`, default `~/projects/skills`).

For layout and how to add a skill, see `README.md` and `AUTHORING.md` — this file covers repo maintenance, not authoring.

## Consumers of this repo

- `dotfiles`: `hacks/sync-skill-runtime-links.sh` (runtime symlinks), `hacks/agent-jobs/*.sh`, cross-harness config in `claude/`, `pi/`, `opencode/` — all reference `SKILLS_ROOT`, not a path inside `dotfiles`.
- `agentic-fleet`: `jarvis/.openjarvis/overlay/__init__.py`'s `_patch_skill_paths()` and `config.toml` — same `SKILLS_ROOT` convention.
- None of these vendor or copy content from here — they all read live from wherever this repo is cloned (default `~/projects/skills`).

## Maintenance commands

```bash
python3 ./hacks/generate-skills-index.py       # regenerate INDEX.md + registry.json
git diff --exit-code -- INDEX.md registry.json # fails if the above found drift — commit the regen
./hacks/validate-skills.sh                     # SKILL.md/manifest.json consistency, adapter links, frontmatter
git ls-files '*.sh' | xargs -r shellcheck --severity=error
git ls-files '*.py' | xargs -r -n1 python3 -m py_compile
```

CI (`.github/workflows/validate.yml`) runs all of the above on every PR and push to `main`.

`hacks/generate-skills-index.py`, `validate-skills.sh`, `new-skill.sh` were moved here from `dotfiles` in the same split — they operate purely on skill content, no `dotfiles`-specific dependency, and this repo's own CI needs them locally rather than reaching into a private repo it can't access.

## Personal-machine-only skills

Some skills (tagged `personal_machine_only: true` in `manifest.json`, e.g. `mobile-android-design`, `weather-forecast`, `location-search`) are deliberately excluded from work machines. The gate lives in the _consuming_ repo (`dotfiles`'s `~/.overlay/local/.enabled` flag file + `hacks/sync-skill-runtime-links.sh`'s `should_skip_skill()`), not here — this repo just carries the flag. Linking is automatic (absent flag = personal machine); there is no per-skill allowlist. Don't assume a skill missing from a given machine's runtime links means it's broken; check whether the flag file exists on that machine first.

`portable` (manifest.json + SKILL.md frontmatter, must match) and `personal_machine_only` are orthogonal fields — a skill can be portable across harnesses _and_ gated to personal machines at the same time. Don't conflate them (this repo shipped with exactly that bug once, in `mobile-android-design`).

## Working in this repo

- One skill = one directory under `portable/<name>/` (cross-harness) or `runtime-specific/<runtime>/<name>/` (harness-specific overlay). Never edit `INDEX.md`/`registry.json` by hand — they're generated.
- Small, focused diffs — one skill's SKILL.md/manifest.json per change where possible.
- If you touch `SKILL.md`'s frontmatter or `manifest.json`, run `validate-skills.sh` before calling it done — the two files share several fields (`portable`, `tags`, description) that must stay in sync.
