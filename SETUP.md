# Skills Setup Summary

## Source of Truth (SOT)

`~/.dotfiles/skills/` — All custom skills authored and versioned here.

### Directory Structure

```
skills/
├── community-work.json      # Skills to install on work laptop
├── community-personal.json  # Skills to install on personal laptop
├── portable/              # 37 portable skills (cross-harness)
│   ├── code-review/
│   └── ...
└── runtime-specific/      # 15 runtime-specific skills
    └── opencode/
        ├── morning/
        ├── standup/
        └── ...
```

## Runtime Skill Locations

OpenCode scans these locations (default, no config needed):
| Path | Used By |
|------|---------|
| `~/.agents/skills/` | **Primary** - OpenCode, Claude Code, Pi |
| `~/.config/opencode/skills/` | Legacy fallback |
| `~/.claude/skills/` | Claude Code fallback |

## Bootstrap Flow

```
Step 8:  sync-skill-runtime-links.sh → links local skills → ~/.agents/skills/
Step 8b: sync-command-runtime-links.sh → portable commands
Step 8c: install_community_skills() → npx skills add --yes --agent opencode from community-{env}.json
```

Community skills install to `~/.agents/skills/` (primary) then symlink to `~/.claude/skills/` (Claude-specific).

## Skills by Location

| Skill Type             | SOT Location                        | Runtime Location             | Access        |
| ---------------------- | ----------------------------------- | ---------------------------- | ------------- |
| **Local portable**     | `skills/portable/`                  | `~/.agents/skills/portable/` | All harnesses |
| **Local runtime**      | `skills/runtime-specific/opencode/` | `~/.config/opencode/skills/` | OpenCode only |
| **Community work**     | Installed via bootstrap             | `~/.agents/skills/`          | All harnesses |
| **Community personal** | Installed via bootstrap             | `~/.agents/skills/`          | All harnesses |

## Key Files

- `~/.work-env-skills` — Work machine flag (triggers work context)
- `~/.personal-machine-skills.txt` — Personal-only allowlist
- `skills/community-{work,personal}.json` — Community skill lists

## Commands

```bash
# Manual skill sync to agents (shared)
./hacks/sync-skill-runtime-links.sh --runtime agents

# Bootstrap with community skills
./bootstrap.sh opencode

# Dry-run
./bootstrap.sh opencode --dry-run
```
