---
name: git-workflow
description: Automate git workflows with worktrees, hooks, and advanced patterns. Use when setting up multi-branch workflows, automating commits, managing hooks, or handling complex merge/rebase scenarios.
version: 0.1.0
portable: true
tags: [git, automation, worktrees, hooks, workflow, version-control]
applies_to: [all, shell, bash, zsh]
---

# Git Workflow Skill

## Scope

Git automation, worktrees, hooks, commit conventions, branch strategies, dotfiles-specific patterns.

## Git Worktree Patterns

### What are Worktrees?
Multiple working directories from same repo, each checked out to different branch.

### Common Use Cases
```bash
# Feature development while main stays clean
git worktree add .worktree/feature-new-zsh-plugin feature/new-zsh-plugin

# Hotfix while working on feature
git worktree add .worktree/hotfix-fix-broken-path hotfix/fix-broken-path

# Review PR without stashing current work
git worktree add .worktree/pr-123 pr/123

# Testing different configurations
git worktree add .worktree/test-macos-sonoma test/macos-sonoma
```

### Worktree Best Practices

**Create worktree**:
```bash
# Good: Repo-local path, branch slug (`/` -> `-`)
git worktree add .worktree/feature-new-plugin feature/new-plugin

# Bad: Nested in main worktree (confusing)
git worktree add ./feature-dir feature/new-plugin
```

**List worktrees**:
```bash
git worktree list
# /Users/user/dotfiles        abc123 [main]
# /Users/user/dotfiles/.worktree/feature-new-plugin def456 [feature/new-plugin]
```

**Remove worktree**:
```bash
# Good: Remove worktree then delete directory
git worktree remove .worktree/feature-new-plugin
# OR: Delete directory first, then prune
rm -rf .worktree/feature-new-plugin && git worktree prune

# Bad: Just deleting directory (leaves git metadata)
rm -rf .worktree/feature-new-plugin  # Worktree still registered!
```

**Worktree for parallel testing**:
```bash
# Test nvim config change without breaking current setup
git worktree add .worktree/experiment-new-lsp experiment/new-lsp
cd .worktree/experiment-new-lsp
./bootstrap.sh --dry-run
# Test changes, iterate
cd -
git worktree remove .worktree/experiment-new-lsp
```

### Worktree Anti-Patterns

❌ **Don't**: Create worktree in same directory
```bash
git worktree add ./feature feature/test  # Confusing structure
```

❌ **Don't**: Forget to remove worktrees
```bash
# Check for orphaned worktrees
git worktree prune --dry-run
```

❌ **Don't**: Try to check out same branch in multiple worktrees
```bash
# This fails (branch already checked out)
git worktree add .worktree/main main  # ERROR!

# Instead: Create new branch
git worktree add .worktree/test-main -b test-main main
```

---

## Git Hooks

### Hook Locations
```bash
# Repository-specific (not tracked)
.git/hooks/pre-commit

# Tracked hooks (dotfiles pattern)
scripts/hooks/pre-commit
# Then symlink: ln -sf ../../scripts/hooks/pre-commit .git/hooks/
```

### Common Hooks for Dotfiles

**pre-commit** - Validation before commit:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate shell scripts
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash|zsh)$'); do
  if ! shellcheck "$file"; then
    echo "❌ ShellCheck failed for $file"
    exit 1
  fi
done

# Validate Lua configs
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.lua$'); do
  if ! luacheck "$file"; then
    echo "❌ Luacheck failed for $file"
    exit 1
  fi
done

# Check for secrets
if git diff --cached | grep -iE '(api[_-]?key|password|secret|token)["\s]*[:=]'; then
  echo "⚠️  WARNING: Possible secret detected in staged changes"
  echo "Review carefully before committing"
  exit 1
fi

echo "✅ Pre-commit checks passed"
```

**post-commit** - Automation after commit:
```bash
#!/usr/bin/env bash

# Auto-sync to backup remote (optional)
if git remote | grep -q backup; then
  git push backup main --quiet &
fi

# Log commit for analytics
echo "$(date +%Y-%m-%d) $(git log -1 --format='%h %s')" >> .git/commit-log
```

**pre-push** - Safety checks before push:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Prevent force push to main
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "main" ]] && git push --dry-run 2>&1 | grep -q "force"; then
  echo "❌ Force push to main is not allowed"
  exit 1
fi

# Check for large files
large_files=$(git diff --cached --name-only | xargs -I{} du -k {} 2>/dev/null | awk '$1 > 1024 {print $2}')
if [[ -n "$large_files" ]]; then
  echo "⚠️  WARNING: Large files detected (>1MB):"
  echo "$large_files"
  read -p "Continue? (y/N) " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi
```

... (rest copied from original runtime-specific doc)
