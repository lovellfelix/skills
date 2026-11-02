# Known Forks Registry

Portable skills sometimes have git-tracked copies in consuming repositories.
Those copies do not update through runtime symlink materialization, so maintainers
must reconcile them separately when the corresponding portable skill changes.

## Registry

| Portable skill | Fork repository | Fork path | Last-synced state |
| --- | --- | --- | --- |
| `lean-ctx` | `lovellfelix/dotfiles` | `opencode/.config/opencode/skills/lean-ctx/SKILL.md` | **Drifted.** The last explicit portable-metadata sync was `dotfiles@28cf831` (2026-08-14). The portable source is now `skills@b95c7bc` (`metadata.version: 0.2.0`), while the fork was subsequently regenerated through `dotfiles@8a61a91` and no longer carries the tracked `metadata.version` and `metadata.tags` fields. |

## Manual sync

The `lean-ctx` fork has OpenCode-specific content, so review and reconcile the
two files rather than replacing the fork blindly. After updating the portable
skill, use this workflow:

```bash
SKILLS_ROOT="${SKILLS_ROOT:-$HOME/projects/skills}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"

git diff --no-index -- \
  "$SKILLS_ROOT/portable/lean-ctx/SKILL.md" \
  "$DOTFILES_ROOT/opencode/.config/opencode/skills/lean-ctx/SKILL.md" || true

# Reconcile the fork, including metadata.version and metadata.tags, then verify:
bash "$SKILLS_ROOT/hacks/check-fork-drift.sh" lean-ctx \
  "$DOTFILES_ROOT/opencode/.config/opencode/skills/lean-ctx"
```

Do not use `hacks/sync-skill-runtime-links.sh` for this copy. That script
materializes runtime symlinks and does not update the flat OpenCode fork above.

## Adding a fork

Add every new git-tracked copy to the registry with its repository, path, and
last known sync commit or drift state. Include a manual reconciliation command
and, when the fork carries frontmatter, verify `metadata.version` and
`metadata.tags` with `hacks/check-fork-drift.sh`.
