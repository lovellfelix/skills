# Skills first pipeline slice

## Goal

Onboard `skills` as a self-contained pipeline product with a narrow MVP: close
the metadata-drift gap this session found between a portable skill's canonical
`SKILL.md` and the git-tracked forks that some harnesses keep instead of a
runtime symlink (e.g. OpenCode's `lean-ctx` copy, which fell out of sync with
the portable version's `metadata:` block until fixed by hand this session).

## Included surfaces

- `portable` — `lovellfelix/skills`

## User outcomes

- A skill fork that's diverged from its portable source is caught by a check
  instead of discovered by hand.
- Anyone updating a portable skill knows which harnesses have their own
  tracked fork and need a manual follow-up edit.

## Constraints

- Keep the scope to 2–4 features total.
- No changes to skill _content_ — this slice is tooling/docs only.
- All features must map to the `portable` surface in `lovellfelix/skills`.

## Non-goals

- Auditing or fixing every existing skill's content
- Changing how runtime symlinking (`sync-skill-runtime-links.sh`, lives in
  dotfiles) works
- Migrating any harness's git-tracked fork to a symlink

## Feature areas and acceptance criteria

### Epic 1: fork-drift detection

- Create a portable feature for a script that, given a skill name and a path
  to a non-symlinked fork elsewhere on disk, reports whether the fork's
  frontmatter (`metadata.version`, `metadata.tags`) matches the portable
  source.
- Acceptance criteria:
  - The script exits non-zero when a fork's `metadata.version` differs from
    its portable source.
  - The script's output names the specific fields that differ.

### Epic 2: known-forks registry

- Create a portable feature documenting every skill currently known to have a
  git-tracked fork outside this repo (starting from OpenCode's `lean-ctx`
  copy in dotfiles) and the manual sync command to run after a portable
  update.
- Acceptance criteria:
  - The doc lists each known fork's repo, path, and last-synced state.
  - The doc is discoverable from this repo's top-level docs, not buried in a
    single skill's own directory.
