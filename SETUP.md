# Skills Setup Summary

## Source of Truth (SOT)

This repo (`lovellfelix/skills`) — all custom skills are authored and versioned here. Consuming repos (`dotfiles`, `agentic-fleet`) read live from wherever it's cloned via `SKILLS_ROOT` (default `~/projects/skills`); none of them vendor or copy content from it. See `CLAUDE.md` for the full consumer list.

### Directory Structure

```
.
├── community-personal.json  # Skills to install on personal laptop
├── portable/                # 47 portable skills (cross-harness)
│   ├── code-review/
│   └── ...
└── runtime-specific/        # harness-specific overlay skills (currently empty)
    └── <runtime>/
```

## Runtime Skill Locations

Two separate mechanisms materialize skills at runtime — there is no single shared directory all three harnesses read from:

| Runtime         | Portable skills (`portable/`)                                                          | Community/marketplace skills                |
| --------------- | -------------------------------------------------------------------------------------- | ------------------------------------------- |
| **OpenCode**    | `~/.config/opencode/skills/portable/` (+ `.../runtime/` for adapters)                  | mirrored into the same `portable/` dir      |
| **Claude Code** | `~/.claude/skills/` (flat — Claude only discovers skills there, no `portable/` subdir) | mirrored into `~/.claude/skills/`           |
| **Pi**          | `~/.agents/skills/` (flat, shared — Pi's `settings.json` scans this directly)          | installed directly into `~/.agents/skills/` |

`~/.agents/skills/` is Pi's own discovery path and the community-skill installer's canonical shared install location — it is **not** a shared intermediate that OpenCode or Claude Code read from; they get their own harness-specific directories from `sync-skill-runtime-links.sh` directly.

## Bootstrap Flow

The sync/bootstrap tooling lives in `dotfiles`, not here — it reads this repo via `SKILLS_ROOT`:

```
Step 8:  hacks/sync-skill-runtime-links.sh → links portable skills into each harness's own directory
           (opencode → ~/.config/opencode/skills/portable/, claude → ~/.claude/skills/, pi → ~/.agents/skills/)
Step 8b: hacks/sync-command-runtime-links.sh → portable commands
Step 8c: install_community_skills() → npx skills add --yes --agent opencode from community-{env}.json
```

Community skills install to `~/.agents/skills/` (shared, and Pi's native scan path) then symlink into `~/.claude/skills/` and `~/.config/opencode/skills/portable/`.

## Skills by Location

| Skill Type             | SOT Location (this repo)           | Runtime Location                                                                                       | Access           |
| ---------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------- |
| **Local portable**     | `portable/`                        | `~/.config/opencode/skills/portable/`, `~/.claude/skills/`, `~/.agents/skills/` (Pi) — one per harness | All harnesses    |
| **Local runtime**      | `runtime-specific/<runtime>/`      | `~/.config/opencode/skills/runtime/` (or the equivalent runtime dir)                                   | Harness-specific |
| **Community work**     | Installed via `dotfiles` bootstrap | `~/.agents/skills/`                                                                                    | All harnesses    |
| **Community personal** | Installed via `dotfiles` bootstrap | `~/.agents/skills/`                                                                                    | All harnesses    |

## Key Files

- `~/.overlay/local/.enabled` — Local overlay flag on the machine running `dotfiles`' bootstrap (triggers machine-specific skill gating; see `CLAUDE.md`'s "Personal-machine-only skills" section)
- `community-personal.json` — Community skill list for this machine class (no `community-work.json` currently)

## Commands

Run from a `dotfiles` checkout, pointed at this repo via `SKILLS_ROOT`:

```bash
# Manual skill sync — omit --runtime to sync all three (opencode, claude, pi)
SKILLS_ROOT=~/projects/skills ~/.dotfiles/hacks/sync-skill-runtime-links.sh --runtime pi

# Bootstrap with community skills
~/.dotfiles/hacks/bootstrap.sh opencode

# Dry-run
~/.dotfiles/hacks/bootstrap.sh opencode --dry-run
```

Maintenance commands that operate on this repo directly (regenerating the index, validating skills, linting) live in `CLAUDE.md`.
