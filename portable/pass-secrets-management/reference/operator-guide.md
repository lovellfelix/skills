# pass: Human-Operator Guide

Everything here runs **in your own terminal**, not an agent's. Agents cannot run `pass` or `gpg` (shell allowlist + `sensitive-file-guard.sh`); their only paths are `scripts/pass-run.sh` and `scripts/pass-store.sh`, documented in `SKILL.md`.

## Store Layout

```
~/.password-store/
├── agent/                           # ONLY subtree agents can read/write (separate zero-cache GPG key)
├── infrastructure/                  # Infrastructure machine credentials
│   ├── age/
│   │   └── key                      # Age encryption key
│   ├── apps/                        # App-specific creds (botkube, infisical, kured, paperless, pocketid, prometheus)
│   ├── database/mysql/              # MySQL creds (backup, phpmyadmin, root)
│   ├── dns/cloudflare/              # Cloudflare (api-key, ddns, email, tunnel)
│   ├── kubernetes/                  # Kubeconfigs (homelab-cluster, mgmt-cluster)
│   ├── network/omada/               # Omada SDN
│   ├── proxmox/                     # PVE (api, cluster-api-users)
│   ├── ssh/                         # SSH keys for machine access
│   │   └── <host>/<user>/           # Key for <user>@<host>
│   │       └── id_ed25519           # Private key (public at id_ed25519.pub)
│   ├── sso/auth0/                   # Auth0 (k3s)
│   └── vpn/                         # VPN creds (blvtx-vpn, privado, tailscale)
├── services/                        # Shared service credentials
│   ├── ai/                          # AI service tokens (chatgpt, claude, gemini, nvidia, openclaw, openrouter)
│   ├── billing/stripe/              # Payment processor
│   ├── cloud/                       # Cloud providers (backblaze, oracle)
│   ├── communication/               # Email/slack (mailgun, slack)
│   ├── containers/                  # Container registries (docker, quay)
│   ├── developers/                  # Dev tools (github, insomnia, netlify)
│   ├── home-automation/             # HA/iot (atuin, home-assistant, mqtt)
│   ├── media/                       # Media stack (lidarr, obsidian, prowlarr, radarr, sonarr, whisparr)
│   ├── projects/                    # Project-specific (gbuzz, etc.)
│   └── storage/                     # Object/block storage (ceph, minio, synology)
├── personal/                        # User's personal secrets
│   ├── atuin
│   ├── email/                       # Email account credentials
│   └── usenet/                      # Usenet provider creds
└── _agent-sessions/                 # Ephemeral session stores (gitignored)
    └── <session-id>/
```

| Namespace          | Purpose                            | Agent access                                   |
| ------------------ | ---------------------------------- | ---------------------------------------------- |
| `agent/`           | Credentials provisioned for agents | Read via `pass-run.sh` (pinentry each time), write via `pass-store.sh` |
| `infrastructure/`  | Machine and infra credentials      | None. Copy into `agent/` if an agent needs it  |
| `services/`        | Shared service credentials         | None. Copy into `agent/` if an agent needs it  |
| `personal/`        | Personal secrets                   | None                                           |
| `_agent-sessions/` | Ephemeral manual session stores    | None (gitignored)                              |

When an agent asks for a credential outside `agent/`, decide whether it should have it, then provision a copy (below). Track which `agent/` entries exist for what purpose in `~/.config/pass/agents/<agent-name>/authorized.conf` if you want an audit list; nothing enforces it.

## SSH Key Convention

SSH keys for machine access follow `infrastructure/ssh/<host>/<user>/id_<type>`:

```
infrastructure/ssh/
└── jarvis-claude/
    └── claude/
        ├── id_ed25519       # Private key (multi-line PEM)
        └── id_ed25519.pub   # Public key (single line)
```

On-disk mirror at `~/.ssh/agents/<host>/<user>/` for direct SSH use.

### Adding a New Secret

```bash
# Create namespace
pass mkdir infrastructure/ssh/my-host/my-user

# Store credential
echo "$VALUE" | pass insert --force infrastructure/ssh/my-host/my-user/id_ed25519
```

### Removing a Secret

```bash
pass rm infrastructure/ssh/my-host/my-user/id_ed25519
pass rm -r infrastructure/ssh/my-host/my-user  # entire user namespace
```

## Agent Subtree (Zero-Cache)

Unlike the rest of the store (default 600s/7200s GPG cache), `agent/` is decrypted
under a separate `GNUPGHOME` (`~/.gnupg-agent`) with `default-cache-ttl 0` /
`max-cache-ttl 0`, using a GPG key dedicated to that subtree. Every `pass-run.sh` call
therefore prompts pinentry on the physical desktop — an agent that bypassed the wrapper
entirely (e.g. wrote and ran a script calling `pass`/`gpg` directly, which is possible
since the allowlist only blocks inline commands, not script files) still cannot get a
secret without a human clicking the prompt. This is what makes the design a boundary
rather than a convenience.

**One-shot setup (human-operator only):**

```bash
scripts/bootstrap-agent-key.sh
```

Creates `~/.gnupg-agent` with the zero-cache config, generates a dedicated
passphrase-protected key (you'll be prompted by pinentry to set the passphrase — a
blank one would make the zero-cache setting pointless, since there'd be nothing to
prompt for), backs the key up into the main store at
`infrastructure/gpg/agent-secrets-key` (encrypted to your regular key), and runs
`pass init -p agent <key-id>`. Idempotent — safe to re-run.

**Portability:** because the agent key is backed up in the main store, bootstrapping a
new machine is the same one command: once `~/.password-store` is synced (it's a git
repo) and your regular GPG key is available, `bootstrap-agent-key.sh` finds the backup
and imports it instead of generating a new key, so the _same_ agent key — and the same
`agent/` secrets — work on every machine.

## Provisioning a Secret for Agent Use

Once the subtree exists (via the bootstrap script above), add credentials to it. If the
agent already has the value (you pasted it in chat, or it just generated/discovered it),
it can store it directly with `scripts/pass-store.sh` (see SKILL.md). As a human
operator you can also do it manually:

```bash
echo "$VALUE" | PASSWORD_STORE_DIR=~/.password-store GNUPGHOME=~/.gnupg-agent pass insert --force agent/openai-api-key
```

### Update an Existing Secret (human operator)

```bash
# Replace first line (password) only
pass insert --force <path> <<EOF
$NEW_SECRET
EOF
```

### Generate a Random Secret

```bash
# Generate 32-char password
pass generate <path> 32


# Generate without symbols (for systems that reject special chars)
pass generate -n <path> 32
```

### List All Secrets

```bash
pass ls                    # Full tree
pass ls infrastructure/    # Subtree
pass find <name>           # Search entry names
PASSWORD_STORE_DIR=~/.password-store GNUPGHOME=~/.gnupg-agent pass ls agent/  # agent subtree
```

## Storing Secrets Outside agent/

```bash
# Interactive entry (avoids history/context leakage)
pass insert <path>

# Non-interactive — pipe via stdin
echo "$SECRET_VALUE" | pass insert --force <path>

# Multi-line secrets (API key + secret on separate lines)
# MUST use --multiline when piping multi-line content (pass v1.7.4+)
pass insert --force --multiline infrastructure/ssh/host/user/id_ed25519 <<EOF
$PRIVATE_KEY_CONTENT
EOF

# One-liner (public keys, tokens — --multiline also works):
cat key.pub | pass insert --force --multiline infrastructure/ssh/host/user/id_ed25519.pub
```

> **Gotcha:** Without `--multiline`, `pass insert --force` may silently exit 1 on piped multi-line input. Always use `--multiline` when writing SSH keys, PEM blocks, or any content with line breaks.

## Operator Hygiene

- Use the value via an env var the child reads, never in argv: `ps` shows every process's arguments. `TOKEN=$(pass show x) cmd` does **not** help if `cmd`'s arguments contain `$TOKEN`, because the shell expands it into argv anyway.
- For HTTP headers, feed curl from stdin: `pass show api/token | head -1 | sed 's/^/Authorization: Bearer /' | curl -H @- https://api.example.com`.
- Never echo, log, or `set -x` around secret values. Turn tracing off (`set +x`) before reading a secret.
- Never write secrets to temp files or commit `.env` files; commit `.env.template` instead.
- Interactive `pass insert <path>` keeps values out of shell history. If you pipe instead, the value must come from a variable or file, not be typed on the command line.
- Scripts need `--force` (no overwrite prompt) and `--multiline` for anything with line breaks.

## SSH Key Rotation

For SSH keys use the generic rotation script at `scripts/rotate-agent-key.sh`:

```bash
# Create first-time key for deploy@10.0.10.100
scripts/rotate-agent-key.sh 10.0.10.100 deploy --create

# Rotate existing claude@jarvis-claude key (auto-backup, pass update, remote deploy)
scripts/rotate-agent-key.sh jarvis-claude claude

# Dry-run to preview
scripts/rotate-agent-key.sh jarvis-claude claude --dry-run

# Custom key type
scripts/rotate-agent-key.sh jarvis-hub cicd --key-type ecdsa

# Custom root user for remote push
scripts/rotate-agent-key.sh 10.0.10.100 ansible --root-user ubuntu
```

What the script does:

1. Backs up the old key to `~/.ssh/agents/<host>/<user>/backup/`
2. Generates a new Ed25519 key
3. Pushes the public key to remote via `root@<host>`
4. Stores the private key in `pass` at `infrastructure/ssh/<host>/<user>/id_ed25519`
5. Stores the public key in `pass` at `...id_ed25519.pub`
6. Verifies the new key works via SSH
7. Auto-restores the backup on verification failure

Wrapper scripts for specific hosts live alongside the keys:

```bash
# ~/.ssh/agents/jarvis-claude/claude/rotate.sh
#!/usr/bin/env bash
SKILLS_ROOT="${SKILLS_ROOT:-$HOME/projects/skills}"
exec "$SKILLS_ROOT/portable/pass-secrets-management/scripts/rotate-agent-key.sh" jarvis-claude claude "$@"
```

## Multi-Line Entries

```bash
# key=value entries: read into the current shell (a `| while` pipeline runs in a subshell and loses the exports)
while IFS='=' read -r key value; do
    export "$key=$value"
done < <(pass show service/config)

# Or parse specific lines
API_KEY=$(pass show service/creds | sed -n '1p')
API_SECRET=$(pass show service/creds | sed -n '2p')

# Clear after use
unset API_KEY API_SECRET
```

## One-Off Isolated Stores

**Human-operator only.** `pass-isolated.sh` calls `pass`/`gpg` directly, so an agent's
Bash tool cannot run it — use this yourself for debugging or one-time setup, not as
something to hand to an agent.

`pass-isolated.sh` in this skill's root packages the pattern below as sourceable functions (`isolated_init`, `isolated_store`, `isolated_retrieve`, `isolated_cleanup`).

Use this pattern when you need to temporarily store a secret that should NOT persist in the main password store — for example, during debugging, testing, or one-time setup flows.

### The Isolation Pattern

```bash
# Store in a temporary, isolated path that won't pollute the main store
PASS_TEMP_DIR=$(mktemp -d)
export PASSWORD_STORE_DIR="$PASS_TEMP_DIR"

# Initialize a temporary pass store
pass init "$(gpg --list-keys --keyid-format long | grep pub | head -1 | awk '{print $2}')"

# Use normally — everything stays isolated
echo "$TEMP_SECRET" | pass insert --force temp/debug-secret
pass show temp/debug-secret

# Cleanup when done
rm -rf "$PASS_TEMP_DIR"
```

### Scoped One-Off with Cleanup Trap

```bash
setup_isolated_pass() {
    local orig_store="$PASSWORD_STORE_DIR"
    local temp_store
    temp_store=$(mktemp -d)

    export PASSWORD_STORE_DIR="$temp_store"
    pass init "$(gpg --list-keys --keyid-format long | grep pub | head -1 | awk '{print $2}')"

    # Register cleanup
    trap "export PASSWORD_STORE_DIR='$orig_store'; rm -rf '$temp_store'" EXIT

    echo "$temp_store"
}

# Usage
isolated_store=$(setup_isolated_pass)
echo "$DISCOVERED_API_KEY" | pass insert --force temp/service-key
# ... use the secret ...
# Cleanup happens automatically via trap
```

### Per-Session Secret Namespace

For multi-step manual workflows, use a session-scoped namespace (keep `_agent-sessions/` gitignored):

```bash
SESSION_ID=$(date +%s)
SESSION_NS="_agent-sessions/$SESSION_ID"

# Store session secrets under this namespace
echo "$TOKEN" | pass insert --force "$SESSION_NS/service-token"
echo "$COOKIE" | pass insert --force "$SESSION_NS/session-cookie"

# Retrieve
pass show "$SESSION_NS/service-token"

# Cleanup entire session namespace
pass rm -r -f "$SESSION_NS"
```

## Version Control for Secrets

While `pass` stores secrets in a git repo by default, follow these practices for safe version control.

### What to Track

| Item                      | Track? | Reason                          |
| ------------------------- | ------ | ------------------------------- |
| Secret paths/directories  | Yes    | Documents what exists           |
| Secret values             | NEVER  | Permanent leakage               |
| `agent/` subtree structure | Yes   | Documents what agents can use   |
| `_agent-sessions/`        | NO     | Ephemeral, should be gitignored |
| `.gpg-id`                 | Yes    | Required for pass to function   |

### Safe Commit Messages

```bash
# GOOD: Describes what changed, not the value
git commit -m "Add agent/npm-auth-token"

# GOOD: Describes removal
git commit -m "Remove retired services/old-service entries"

# BAD: Never include secret value in commit message
git commit -m "feat: add ghp_xxxxxxxxxxxx for github"
```

### Listing Secret Changes (Safe)

```bash
# See what paths were added/removed (no values exposed)
cd ~/.password-store
git log --oneline --diff-filter=A --name-only  # Added secrets
git log --oneline --diff-filter=D --name-only  # Removed secrets
git diff HEAD~1 --name-status                  # Recent changes
```

### Backup Strategy

```bash
# Export encrypted store (safe — GPG-encrypted)
cd ~/.password-store
git bundle create ~/pass-backup-$(date +%Y%m%d).bundle --all

# Verify backup
git bundle verify ~/pass-backup-$(date +%Y%m%d).bundle
```
