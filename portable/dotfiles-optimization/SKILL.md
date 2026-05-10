---
name: dotfiles-optimization
description: Use when improving shell configs, dotfiles layout, or local automation with safe, validated changes.
metadata:
  version: 0.1.1
  portable: true
  tags: [dotfiles, shell, zsh, nvim, stow, automation, portable]
---

# Dotfiles Optimization

## Scope

Shell configs (zsh, bash), Neovim (Lua), tmux, git, and GNU Stow dotfiles management.

## Shell Configuration Best Practices

### Performance
- Lazy load plugins and language managers.
- Background non-critical startup work when safe.
- Cache completions and avoid unnecessary recomputation.
- Keep PATH minimal, deduplicated, and valid.
- Profile startup regularly to catch regressions.

### Structure

```bash
# Good: XDG Base Directory compliant
~/.config/zsh/.zshrc
~/.config/zsh/.zshenv
~/.config/nvim/init.lua

# Avoid: Home directory sprawl
~/.zshrc
~/.vimrc
```

### Security
- Ignore secrets (`.env`, `.env-*`, `*secrets*`, `.envrc`).
- Track only templates (for example `.env.template`).
- Never hardcode credentials, tokens, or API keys.
- Use safe defaults in env expansion (`${VAR:-default}`).

## Zsh Patterns

### Completion Ordering

```bash
# Correct: plugin/completion sources before compinit
zinit light zsh-users/zsh-completions
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
```

### PATH Hygiene

```bash
path_prepend() { [[ -d "$1" ]] && PATH="$1:$PATH"; }
path_append() { [[ -d "$1" ]] && PATH="$PATH:$1"; }
typeset -U path PATH
```

### Lazy Loading Example

```bash
nvm() {
  unset -f nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm "$@"
}
```

## Neovim (Lua) Patterns

- Prefer event-driven lazy loading for plugins.
- Load LSP only for relevant filetypes.
- Defer non-critical UI plugins.
- Profile plugin startup before and after changes.

## GNU Stow Practices

- Always dry-run before mutating links.
- Use restow for updates.
- Treat `--adopt` as a high-risk operation and review results carefully.

## Validation Commands

| Tool | Command |
|------|---------|
| Shell syntax | `bash -n script.sh` |
| Shell lint | `shellcheck script.sh` |
| Zsh syntax | `zsh -n ~/.zshrc` |
| Lua lint | `selene .` |
| Stow preview | `stow --dry-run --verbose=2 <module>` |

## Cross-Harness Notes

- Keep repo-managed skills/config canonical so Claude, OpenCode, Pi, Copilot, and Cursor stay aligned where practical.
- Prefer shared portable sources over runtime-local edits; use `~/.agents/memory/` for durable/session context.
- After changing skills or agents, run the repo validation/sync commands before considering the update complete.

## Working Style

- Keep diffs minimal and targeted.
- Validate immediately after each change.
- Report concrete impact (startup time, fewer warnings, safer defaults).
