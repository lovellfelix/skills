# Known Forks Registry

Portable skills sometimes have git-tracked copies in consuming repositories.
Those copies do not update through runtime symlink materialization, so maintainers
must reconcile them separately when the corresponding portable skill changes.

## Registry

| Portable skill | Fork repository | Fork path | Last-synced state |
| --- | --- | --- | --- |
| _(none)_ | | | The `lean-ctx` fork in `lovellfelix/dotfiles` was retired along with the skill (2026-11-19). |

## Manual sync

When a fork is registered, compare it with the portable source and reconcile it
by hand, then verify frontmatter with `hacks/check-fork-drift.sh`:

```bash
SKILLS_ROOT="${SKILLS_ROOT:-$HOME/projects/skills}"

git diff --no-index -- \
  "$SKILLS_ROOT/portable/<skill>/SKILL.md" "<fork-path>/SKILL.md" || true
bash "$SKILLS_ROOT/hacks/check-fork-drift.sh" <skill> "<fork-path>"
```

Do not use `hacks/sync-skill-runtime-links.sh` for forks. That script
materializes runtime symlinks and does not update flat git-tracked copies.

## Adding a fork

Add every new git-tracked copy to the registry with its repository, path, and
last known sync commit or drift state. Include a manual reconciliation command
and, when the fork carries frontmatter, verify `metadata.version` and
`metadata.tags` with `hacks/check-fork-drift.sh`.
