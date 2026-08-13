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

OpenCode scans these locations (default, no config needed):

| Path                         | Used By                                 |
| ---------------------------- | --------------------------------------- |
| `~/.agents/skills/`          | **Primary** - OpenCode, Claude Code, Pi |
| `~/.config/opencode/skills/` | Legacy fallback                         |
| `~/.claude/skills/`          | Claude Code fallback                    |

## Bootstrap Flow

The sync/bootstrap tooling lives in `dotfiles`, not here — it reads this repo via `SKILLS_ROOT`:

```
Step 8:  hacks/sync-skill-runtime-links.sh → links local skills → ~/.agents/skills/
Step 8b: hacks/sync-command-runtime-links.sh → portable commands
Step 8c: install_community_skills() → npx skills add --yes --agent opencode from community-{env}.json
```

Community skills install to `~/.agents/skills/` (primary) then symlink to `~/.claude/skills/` (Claude-specific).

## Skills by Location

| Skill Type             | SOT Location (this repo)           | Runtime Location                                             | Access           |
| ---------------------- | ---------------------------------- | ------------------------------------------------------------ | ---------------- |
| **Local portable**     | `portable/`                        | `~/.agents/skills/portable/`                                 | All harnesses    |
| **Local runtime**      | `runtime-specific/<runtime>/`      | `~/.config/opencode/skills/` (or the equivalent runtime dir) | Harness-specific |
| **Community work**     | Installed via `dotfiles` bootstrap | `~/.agents/skills/`                                          | All harnesses    |
| **Community personal** | Installed via `dotfiles` bootstrap | `~/.agents/skills/`                                          | All harnesses    |

## Key Files

- `~/.overlay/local/.enabled` — Local overlay flag on the machine running `dotfiles`' bootstrap (triggers machine-specific skill gating; see `CLAUDE.md`'s "Personal-machine-only skills" section)
- `community-personal.json` — Community skill list for this machine class (no `community-work.json` currently)

## Commands

Run from a `dotfiles` checkout, pointed at this repo via `SKILLS_ROOT`:

```bash
# Manual skill sync to agents (shared)
SKILLS_ROOT=~/projects/skills ~/.dotfiles/hacks/sync-skill-runtime-links.sh --runtime agents

# Bootstrap with community skills
~/.dotfiles/hacks/bootstrap.sh opencode

# Dry-run
~/.dotfiles/hacks/bootstrap.sh opencode --dry-run
```

Maintenance commands that operate on this repo directly (regenerating the index, validating skills, linting) live in `CLAUDE.md`.
