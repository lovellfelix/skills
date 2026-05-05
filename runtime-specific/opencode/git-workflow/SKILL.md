---
name: git-workflow
description: Automate git workflows with worktrees, hooks, and advanced patterns. Use when setting up multi-branch workflows, automating commits, managing hooks, or handling complex merge/rebase scenarios.
version: 0.1.0
portable: false
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

### Installing Hooks in Dotfiles Repo

**Approach 1: Bootstrap script**
```bash
# In bootstrap.sh
setup_git_hooks() {
  echo "Setting up git hooks..."
  for hook in scripts/hooks/*; do
    hook_name=$(basename "$hook")
    ln -sf "../../scripts/hooks/$hook_name" ".git/hooks/$hook_name"
    chmod +x "$hook"
  done
}
```

**Approach 2: Core.hooksPath** (git 2.9+)
```bash
# Set global hooks directory
git config core.hooksPath scripts/hooks

# Now all hooks in scripts/hooks/ are active
```

---

## Commit Conventions

### Dotfiles Commit Style

**Format**: `<type>(<scope>): <description>`

**Types**:
- `feat`: New feature (new alias, plugin, config section)
- `fix`: Bug fix (broken PATH, completion issue)
- `chore`: Maintenance (lockfile update, cleanup)
- `docs`: Documentation (README, comments)
- `refactor`: Code restructure (reorganize zshrc)
- `perf`: Performance (lazy loading, optimization)
- `style`: Formatting (indentation, whitespace)
- `test`: Testing (validation scripts)

**Scopes** (this repo):
- `zsh`, `bash`, `nvim`, `tmux`, `git`, `opencode`, `stow`

**Examples**:
```bash
git commit -m "feat(zsh): add lazy loading for nvm"
git commit -m "fix(nvim): correct LSP keybinding conflict"
git commit -m "perf(zsh): optimize completion loading order"
git commit -m "chore(nvim): update plugin lockfile"
git commit -m "docs(README): add installation instructions"
```

### Commit Message Template

Create `.gitmessage`:
```
<type>(<scope>): <summary>

# Why this change?
# 

# What changed?
# 

# Breaking changes?
# 

# Types: feat, fix, chore, docs, refactor, perf, style, test
# Scopes: zsh, bash, nvim, tmux, git, opencode, stow
```

Enable:
```bash
git config commit.template .gitmessage
```

---

## Branch Strategies

### Dotfiles Branch Patterns

**main** - Stable, working configuration
```bash
# Always keep main deployable
git checkout main
./bootstrap.sh  # Should always work
```

**feature/** - New additions
```bash
git checkout -b feature/tmux-integration
# Experiment, test, iterate
git push -u origin feature/tmux-integration
# PR to main when ready
```

**hotfix/** - Urgent fixes
```bash
git checkout -b hotfix/broken-path main
# Fix immediately
git push -u origin hotfix/broken-path
# Fast-track merge to main
```

**experiment/** - Risky changes
```bash
git checkout -b experiment/new-plugin-manager
# Try radical changes
# Delete branch if it doesn't work out
```

**machine/** - Machine-specific configs
```bash
# Per-machine branches for non-portable changes
git checkout -b machine/macbook-pro
git checkout -b machine/linux-desktop

# Keep machine-specific in separate branches
# Cherry-pick portable changes to main
```

### Branch Protection

**Prevent accidental main deletion**:
```bash
# In .git/config
[branch "main"]
  remote = origin
  merge = refs/heads/main
  
# Prevent force push
git config branch.main.pushRemote no_push  # Invalid remote prevents push
```

---

## Git Aliases for Dotfiles

### Essential Aliases

```bash
# Quick status
git config --global alias.st 'status -sb'

# Concise log
git config --global alias.lg 'log --oneline --graph --decorate --all -20'

# Show files changed in last commit
git config --global alias.last 'log -1 --stat'

# Undo last commit (keep changes)
git config --global alias.undo 'reset HEAD~1 --soft'

# Amend commit without editing message
git config --global alias.amend 'commit --amend --no-edit'

# Interactive rebase on last N commits
git config --global alias.rebase-n '!f() { git rebase -i HEAD~$1; }; f'

# Sync with remote (fetch + rebase)
git config --global alias.sync '!git fetch --all && git rebase origin/main'

# Show worktrees
git config --global alias.wt 'worktree list'

# Cleanup merged branches
git config --global alias.cleanup '!git branch --merged main | grep -v "main" | xargs -r git branch -d'

# Stash with message
git config --global alias.stash-msg '!f() { git stash push -m "$1"; }; f'

# Show diff of staged changes
git config --global alias.staged 'diff --cached'

# Show what would be committed
git config --global alias.preview 'diff --cached --name-status'
```

### Dotfiles-Specific Aliases

```bash
# Dry-run stow before actual deploy
git config alias.check-stow '!./bootstrap.sh --dry-run'

# Test zsh config syntax
git config alias.check-zsh '!zsh -n zsh/.config/zsh/.zshrc'

# Test all shell scripts
git config alias.check-sh '!find . -name "*.sh" -o -name "*.bash" | xargs shellcheck'

# Show files that would be symlinked
git config alias.show-stow '!stow --dry-run --verbose=2 zsh nvim tmux 2>&1 | grep "LINK:"'
```

---

## Git Performance Optimization

### Faster Operations

```bash
# Enable parallel fetch
git config --global fetch.parallel 0  # Auto-detect CPU cores

# Enable file system monitor (macOS/Linux)
git config --global core.fsmonitor true
git config --global core.untrackedCache true

# Better compression
git config --global core.compression 9

# Faster diffs
git config --global diff.algorithm histogram

# Reuse recorded conflict resolutions
git config --global rerere.enabled true
```

### Repository Maintenance

```bash
# Run periodically (or in cron)
git maintenance start  # Auto-maintenance

# Manual optimization
git gc --aggressive --prune=now

# Clean up worktree metadata
git worktree prune

# Remove unreachable objects
git prune

# Verify repository integrity
git fsck
```

---

## Advanced Patterns

### Subtree for Sharing Configs

Share subset of dotfiles (e.g., just nvim config):
```bash
# Create subtree branch
git subtree split --prefix=nvim/.config/nvim -b nvim-config

# Push to separate repo
git push nvim-remote nvim-config:main

# Update subtree from separate repo
git subtree pull --prefix=nvim/.config/nvim nvim-remote main
```

### Sparse Checkout for Large Repos

Only checkout specific directories:
```bash
git clone --no-checkout https://github.com/user/dotfiles.git
cd dotfiles
git sparse-checkout init --cone
git sparse-checkout set zsh nvim  # Only these directories
git checkout main
```

### Bisect for Finding Regressions

Find commit that broke something:
```bash
git bisect start
git bisect bad  # Current commit is broken
git bisect good abc123  # Known good commit

# Git checks out middle commit
./bootstrap.sh && test-command  # Test if broken

git bisect good  # or 'bad'
# Repeat until git finds the culprit commit

git bisect reset  # Return to original state
```

---

## Automation Scripts

### Auto-commit on Change

Watch for changes and auto-commit (development only):
```bash
#!/usr/bin/env bash
# scripts/auto-commit.sh

while true; do
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "chore: auto-commit $(date +%H:%M:%S)"
  fi
  sleep 300  # Every 5 minutes
done
```

### Sync Across Machines

Push changes automatically:
```bash
#!/usr/bin/env bash
# scripts/sync.sh

set -euo pipefail

# Pull latest
git pull --rebase origin main

# Add changes
git add -A

# Commit if changes exist
if ! git diff --cached --quiet; then
  git commit -m "chore(sync): auto-sync from $(hostname) at $(date +%Y-%m-%d)"
  git push origin main
  echo "✅ Synced successfully"
else
  echo "ℹ️  No changes to sync"
fi
```

### Backup to Multiple Remotes

```bash
#!/usr/bin/env bash
# scripts/backup.sh

remotes=("origin" "backup" "github" "gitlab")

for remote in "${remotes[@]}"; do
  if git remote | grep -q "^$remote$"; then
    echo "Pushing to $remote..."
    git push "$remote" main || echo "⚠️  Failed to push to $remote"
  fi
done
```

---

## Security Best Practices

### Never Commit Secrets

**Git-ignore patterns** (`.gitignore`):
```
# Environment files
.env
.env.*
*.env

# Secrets
*secret*
*password*
*key.json
credentials.json

# SSH keys
*.pem
*.key
id_rsa
id_ed25519

# API tokens
.token
*.token
```

**Check for secrets before commit**:
```bash
# Add to pre-commit hook
git diff --cached | grep -iE 'password|secret|api[_-]?key|token' && exit 1
```

### Clean Committed Secrets

If you accidentally commit secrets:
```bash
# Remove file from history (DESTRUCTIVE)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret-file" \
  --prune-empty --tag-name-filter cat -- --all

# Or use BFG Repo-Cleaner (faster)
bfg --delete-files secret-file.txt
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Force push (coordinate with team!)
git push --force --all
```

---

## Troubleshooting

### Issue: Detached HEAD after worktree operations
```bash
# Diagnosis
git status  # "HEAD detached at abc123"

# Fix
git checkout main  # Or your intended branch
```

### Issue: Worktree directory deleted but still registered
```bash
# Diagnosis
git worktree list  # Shows missing directory

# Fix
git worktree prune
```

### Issue: Cannot switch branches (unstaged changes)
```bash
# Quick stash
git stash push -m "WIP: switching branches"

# Switch branch
git checkout other-branch

# Return and restore
git checkout original-branch
git stash pop
```

### Issue: Merge conflict in dotfiles
```bash
# Accept theirs for binary files (plugins, lockfiles)
git checkout --theirs nvim/.config/nvim/lazy-lock.json
git add nvim/.config/nvim/lazy-lock.json

# Accept ours for core configs
git checkout --ours zsh/.config/zsh/.zshrc
git add zsh/.config/zsh/.zshrc

# Manual resolution for important configs
git mergetool
```

### Issue: Large repository size
```bash
# Find large files
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | sed -n 's/^blob //p' \
  | sort --numeric-sort --key=2 \
  | tail -20

# Remove large files from history
git filter-branch --index-filter \
  'git rm --cached --ignore-unmatch path/to/large-file' HEAD
```

---

## Validation Commands

| Command | Purpose |
|---------|---------|
| `git status` | Check working directory state |
| `git log --oneline -10` | Recent commits |
| `git worktree list` | Active worktrees |
| `git remote -v` | Remote repositories |
| `git branch -a` | All branches (local + remote) |
| `git diff --check` | Check for whitespace errors |
| `git fsck` | Verify repository integrity |
| `git gc --auto` | Cleanup if needed |

---

## Response Format

When working with git operations:

```bash
# Worktree: .worktree/feature-new-plugin (feature/new-plugin)
# Action: Created and switched to worktree
# Files modified: zsh/.config/zsh/.zshrc
# Validation: git status (clean)

git worktree add .worktree/feature-new-plugin -b feature/new-plugin
cd .worktree/feature-new-plugin
# Make changes...
git commit -m "feat(zsh): add new plugin"
```

Always validate git operations, check status, explain branch/worktree state clearly.
