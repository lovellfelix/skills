---
name: pass-secrets-management
description: Use when an agent needs to use or store an API key, token, password, or other credential backed by the pass CLI (pass-run.sh / pass-store.sh), or when a human operator is provisioning, rotating, or backing up credentials in ~/.password-store.
metadata:
  version: 0.6.0
  portable: true
  tags:
    [
      pass,
      secrets,
      passwords,
      credentials,
      security,
      gpg,
      password-store,
      agent-automation,
      ssh,
      key-rotation,
      rotate-agent-key,
      pass-run,
      pass-store,
    ]
---

# Pass Secrets Management

Secrets live in `pass` (GPG-encrypted, `~/.password-store/`). **Agents never run `pass` or `gpg`.** Both are blocked by the shell allowlist (lean-ctx, shared across Claude Code/OpenCode/Pi) and `sensitive-file-guard.sh`. That's structural, not a gap to work around.

Agents get two wrappers, both restricted to the `agent/` subtree:

| Need                    | Use                       | Behavior                                                                                                    |
| ----------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Use a secret            | `scripts/pass-run.sh`     | Decrypts (pinentry prompt on the desktop every call), injects into the child's **env**, censors output to `[REDACTED]` |
| Store a secret          | `scripts/pass-store.sh`   | Encrypts from stdin, or `--generate`s one the agent never sees. No pinentry needed                         |

Human-operator tasks (layout, provisioning, rotation, bootstrap, backups): `reference/operator-guide.md`.

## Use a secret: `pass-run.sh`

```bash
scripts/pass-run.sh --secret agent/<name> [--as ENV_VAR] [--secret ...] [--full] -- <command...>
```

- Env var defaults to the last path component, uppercased, `-` → `_` (`agent/github-token` → `GITHUB_TOKEN`). `--as` overrides it.
- First line of the entry only, unless `--full`.
- Output is buffered until the command exits (no streaming), then censored.

**Quoting rule:** the variable exists only inside the child process. Anything you write after `--` is expanded by *your* shell first, so `"$TOKEN"` there becomes an empty string. Either use a tool that reads the env var itself, or single-quote a `sh -c` script:

```bash
# Tool reads the env var natively (best)
scripts/pass-run.sh --secret agent/github-token -- gh pr list

# Header from stdin: not in argv, invisible to `ps`
scripts/pass-run.sh --secret agent/openai-api-key --as OPENAI_API_KEY -- \
  sh -c 'printf "Authorization: Bearer %s\n" "$OPENAI_API_KEY" | curl -sS -H @- https://api.openai.com/v1/models'

# Several secrets
scripts/pass-run.sh --secret agent/db-user --as DB_USER --secret agent/db-pass --as DB_PASS -- ./migrate.sh
```

Avoid `sh -c 'curl -H "Authorization: Bearer $TOKEN" …'`: it works, but puts the token in curl's argv where `ps` can read it. Use `-H @-` as above.

## Store a secret: `pass-store.sh`

```bash
printf '%s' "$NEW_API_KEY" | scripts/pass-store.sh --secret agent/openai-api-key   # value you already have
scripts/pass-store.sh --secret agent/internal-db-password --generate 40             # random, never shown
```

`--full` stores multi-line stdin verbatim (keys, PEM blocks). Storing doesn't weaken the read side: getting the value back still needs a human to approve a `pass-run.sh` decrypt.

## Need a secret outside `agent/`?

`infrastructure/`, `services/`, and `personal/` are unreachable for agents by design. Don't look for a way around it. Ask the user to provision a copy:

```text
SECRET NEEDED: agent/<proposed-name>
Source (if known): services/<...>
Used for: <command / service>
Scope: <read-only? which environment?>
```

## Never

- Run `pass`, `gpg`, or a script you wrote that calls them.
- Read `~/.password-store`, `~/.gnupg*`, or `*.gpg` files.
- Put a secret value in argv, logs, echoed output, files, commits, session memory, or your reply.
- Paste a secret the user gave you into a later command line. Pipe it to `pass-store.sh` once, then use `pass-run.sh`.
- Retry a `pass-run.sh` call that failed because the human denied or cancelled pinentry. Report it and stop.

## Common mistakes

| Mistake                                                       | Fix                                                        |
| ------------------------------------------------------------- | ---------------------------------------------------------- |
| `pass-run.sh … -- curl -H "Bearer $TOKEN"` sends an empty token | Single-quoted `sh -c`, header via `-H @-`                  |
| `pass show agent/x` blocked                                   | `pass-run.sh --secret agent/x -- <cmd>`                    |
| Entry has `username:`/`url:` lines and the token looks wrong  | Default is first line only; use `--full` only when needed  |
| `refusing '<path>': only secrets under agent/`                | Ask the user to provision it under `agent/`                |
| Long-running command shows no output                          | Expected: output is buffered and released at exit          |

## Cross-harness notes

- The wrappers ship in this skill, so every harness that links the skill has them. Both must be on the lean-ctx shell allowlist by basename; `pass`/`gpg` never should be.
- Claude Code adds `sensitive-file-guard.sh`, which blocks reads of `.password-store`/`.gpg`/`.gnupg-agent` paths. Pi has no hook layer: its enforcement is the allowlist plus its `secrets.md` rule.
- `agent/` uses a separate `GNUPGHOME` (`~/.gnupg-agent`) with a zero-TTL cache, so even a wrapper bypass can't decrypt without a human clicking pinentry. See `reference/operator-guide.md`.
