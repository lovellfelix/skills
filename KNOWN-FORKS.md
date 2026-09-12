# Known Forks Registry

Skills in this repo sometimes have git-tracked forks outside of it — copies that were extracted or vendored into a consuming repo and may drift from the portable source. This document tracks every known fork so maintainers can keep them in sync.

## Forks

| Skill | Fork Repo | Fork Path | Fork Type | Last Synced | Notes |
|-------|-----------|-----------|-----------|-------------|-------|
| **lean-ctx** | `lovellfelix/dotfiles` | `opencode/skills/lean-ctx/` | Native copy (OpenCode adapter) | 2026-08-09 (repo split) | OpenCode's `lean-ctx` adapter mode is `native`, so dotfiles carries its own copy under the OpenCode skills directory rather than a symlink to the portable source. |

## Sync Commands

After updating a portable skill that has a known fork, run the corresponding manual sync command to propagate the change to the fork location.

### lean-ctx → dotfiles (OpenCode native copy)

```bash
# From the dotfiles repo, re-sync the OpenCode native skill copy from the portable source:
cp "$SKILLS_ROOT/portable/lean-ctx/SKILL.md" ~/.config/opencode/skills/lean-ctx/SKILL.md
cp "$SKILLS_ROOT/portable/lean-ctx/manifest.json" ~/.config/opencode/skills/lean-ctx/manifest.json
```

Or, to sync all portable skills into all runtimes at once (including lean-ctx):

```bash
SKILLS_ROOT=~/projects/skills ~/.dotfiles/hacks/sync-skill-runtime-links.sh
```

## Adding a New Fork

When a consuming repo vendors or copies a skill rather than symlinking it, add an entry to the table above with:

- **Skill** — the portable skill name from this repo
- **Fork Repo** — the GitHub repo (`owner/repo`) holding the fork
- **Fork Path** — path within that repo to the forked files
- **Fork Type** — `native copy`, `vendored`, or `symlink` (if symlink, prefer fixing the symlink instead)
- **Last Synced** — date or commit the fork was last synced from this repo
- **Notes** — any context about why the fork exists or sync caveats