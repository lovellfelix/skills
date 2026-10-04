---
name: git-workflow
description: Use when setting up git worktrees, writing or installing git hooks, recovering from a bad merge/rebase/reset, untangling history, or automating multi-branch workflows beyond routine commit/push. Not for commit message wording (see commit-messages).
metadata:
  version: 0.2.0
  portable: true
  tags: [git, automation, worktrees, hooks, rebase, recovery, version-control, workflow]
  applies_to: [all, shell, bash, zsh]
---

# Git Workflow

Related: `commit-messages` (message wording), `github` (PRs, CI via `gh`).

## Worktrees

Parallel checkouts of one repo, each on its own branch. Use them to review a PR, hotfix, or let an agent work without disturbing your main checkout.

```bash
# Repo-local, gitignored dir; branch slug with / -> -
git worktree add .worktree/feature-new-plugin -b feature/new-plugin main
git fetch origin pull/123/head:pr-123 && git worktree add .worktree/pr-123 pr-123  # GitHub PR
git worktree list
git worktree remove .worktree/feature-new-plugin   # not rm -rf: that leaves metadata
git worktree prune --dry-run                        # find stale registrations
```

- Add `.worktree/` to `.gitignore` (or use a sibling dir like `../repo-wt/<slug>`) so worktrees never get committed.
- A branch can only be checked out in one worktree. Need `main` twice? `git worktree add .worktree/main-test -b main-test main`.
- Each worktree needs its own dependency install / build dir; don't share `node_modules` or virtualenvs across them.

## Hooks

Track hooks in the repo and point git at them, instead of hand-copying into `.git/hooks/`:

```bash
mkdir -p .githooks && git config core.hooksPath .githooks
```

If the repo already uses a hook manager (`pre-commit`, `lefthook`, `husky`), add hooks there instead.

**pre-commit**: lint only what's staged, NUL-safe:

```bash
#!/usr/bin/env bash
set -euo pipefail

mapfile -d '' files < <(git diff --cached --name-only -z --diff-filter=ACM -- '*.sh' '*.bash')
if ((${#files[@]})); then
  shellcheck "${files[@]}"
fi

if git diff --cached -U0 | grep -qiE '^\+.*(api[_-]?key|password|secret|token)["'"'"' ]*[:=]'; then
  echo "Possible secret in staged changes. Review, or bypass once with --no-verify." >&2
  exit 1
fi
```

**pre-push**: git passes `<local-ref> <local-sha> <remote-ref> <remote-sha>` lines on stdin. Use them; don't re-run `git push` inside the hook.

```bash
#!/usr/bin/env bash
set -euo pipefail
zero=0000000000000000000000000000000000000000

while read -r _local_ref local_sha remote_ref remote_sha; do
  [[ "$local_sha" == "$zero" ]] && continue                  # branch deletion
  if [[ "$remote_ref" == refs/heads/main && "$remote_sha" != "$zero" ]] &&
     ! git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
    echo "Refusing non-fast-forward push to main." >&2
    exit 1
  fi
  range=$([[ "$remote_sha" == "$zero" ]] && echo "$local_sha" || echo "$remote_sha..$local_sha")
  git rev-list --objects "$range" | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' |
    awk '$1=="blob" && $2>1048576 {print "Large file (>1MB): " $3; bad=1} END {exit bad}' || exit 1
done
```

Hooks are local guardrails, not enforcement. Server-side rules (branch protection, CI) are the real gate.

## Rebase and merge

- Rebase only branches nobody else has pulled. On shared branches, merge.
- Update a feature branch: `git fetch origin && git rebase origin/main`. Conflicts: fix, `git add`, `git rebase --continue`; bail with `git rebase --abort`.
- Enable `git config rerere.enabled true` when repeatedly rebasing long-lived branches.
- After rewriting your own pushed branch: `git push --force-with-lease`, never bare `--force`.
- Squash fixups before review: `git commit --fixup <sha>` then `git rebase --autosquash origin/main` (add `-i` when interactive editing is available).

## Recovery

Almost nothing committed is lost. Check the reflog before panicking.

| Situation                         | Fix                                                                      |
| --------------------------------- | ------------------------------------------------------------------------ |
| Bad reset / rebase / amend        | `git reflog`, then `git reset --hard <sha-before>` (stash work first)    |
| Undo last commit, keep changes    | `git reset --soft HEAD~1`                                                |
| Undo a pushed commit              | `git revert <sha>` (never rewrite shared history)                        |
| Revert a merge commit             | `git revert -m 1 <merge-sha>`                                            |
| Committed to the wrong branch     | `git branch fix-branch && git reset --hard origin/<branch>` (unpushed)   |
| Deleted branch                    | `git reflog` / `git branch <name> <sha>`                                 |
| Lost stash                        | `git fsck --unreachable \| grep commit`, then `git stash apply <sha>`    |
| Find the commit that broke it     | `git bisect start <bad> <good>`; `git bisect run <test-cmd>`             |

Before any `reset --hard`, `clean -fd`, or force push: `git status` and `git stash` (or a backup branch) first.

## Validate

- `bash -n` and `shellcheck` every hook.
- Test hooks on a throwaway branch before relying on them.
