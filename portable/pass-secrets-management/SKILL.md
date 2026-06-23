---
name: pass-secrets-management
description: Use when agents need to retrieve, store, or manage secrets/passwords/credentials using the pass CLI, including one-off secret storage for isolated leakage prevention in autonomous workflows.
metadata:
  version: 0.2.0
  portable: true
  tags: [pass, secrets, passwords, credentials, security, gpg, password-store, agent-automation]
---

# Pass Secrets Management

## Overview

Use the `pass` CLI (standard Unix password manager) for all secrets management in agent workflows. Pass provides GPG-encrypted storage with deterministic paths, enabling agents to autonomously retrieve and store credentials without leaking secrets to logs, context, or other processes.

**Core principle:** Every secret goes through `pass`. No exceptions. No hardcoded values, no env vars with raw secrets, no temporary files.

## When to Use

- Retrieving API keys, tokens, or passwords for service authentication
- Storing newly generated or discovered credentials
- One-off secret storage during debugging or setup workflows
- Sharing secrets across agent sessions without context leakage
- Rotating credentials and updating stored values

## Prerequisites

- `pass` installed (`brew install pass` on macOS)
- GPG key initialized (`pass init <gpg-id>`)
- Store location: typically `~/.password-store/`

## Migration from Legacy Structure

If your pass store uses a flat `homelab/` catch-all structure, migrate to the agent-friendly namespace convention first.

```bash
# Preview changes (safe — no modifications)
./pass-migrate.sh --dry-run

# Execute migration (creates backup automatically)
./pass-migrate.sh --execute

# Rollback if needed
./pass-migrate.sh --rollback
```

**Files:**
- `MIGRATION-PLAN.md` — Full migration mapping and rationale
- `POST-MIGRATION-REFERENCE.md` — Quick reference for finding secrets after migration
- `pass-migrate.sh` — Migration script with dry-run/execute/rollback modes

## Agent Namespace Convention

Organize secrets by agent category and purpose. This keeps secrets scoped, avoids cross-contamination, and makes auditing easier.

### Recommended Directory Structure

```
~/.password-store/
├── agents/                          # Agent-specific secrets
│   ├── orchestrator/                # Orchestrator agent
│   │   ├── github/
│   │   │   └── token
│   │   └── slack/
│   │       └── webhook-url
│   ├── language-coder/              # Language coder agent
│   │   ├── npm/
│   │   │   └── auth-token
│   │   └── pypi/
│   │       └── api-key
│   └── sre-debugger/                # SRE debugger agent
│       ├── kubernetes/
│       │   └── kubeconfig-token
│       └── ssh/
│           └── deploy-key
├── services/                        # Shared service credentials
│   ├── aws/
│   │   ├── production/
│   │   │   ├── access-key
│   │   │   └── secret-key
│   │   └── staging/
│   │       ├── access-key
│   │       └── secret-key
│   ├── github/
│   │   └── personal-access-token
│   └── homelab/
│       ├── age/
│       │   └── key
│       └── ai/
│           └── chatgpt/
│               └── api-key
├── personal/                        # Personal/user-scoped secrets
│   └── ssh/
│       └── github-personal
└── _agent-sessions/                 # Ephemeral session stores (gitignored)
    └── <session-id>/
```

### Namespace Rules

| Namespace | Purpose | Access |
|-----------|---------|--------|
| `agents/<agent-name>/` | Agent-specific credentials | Only that agent |
| `services/<service>/` | Shared service credentials | All authorized agents |
| `personal/` | User's personal secrets | Requires user permission |
| `_agent-sessions/` | Ephemeral session-scoped stores | Creating agent only |

### Adding a New Agent Namespace

```bash
# Create namespace for a new agent
pass mkdir agents/my-new-agent

# Store agent-specific credentials
echo "$TOKEN" | pass insert --force agents/my-new-agent/service/token

# Verify
pass ls agents/my-new-agent/
```

### Removing an Agent Namespace

```bash
# Remove entire agent namespace (requires confirmation)
pass rm -r -f agents/old-agent

# Or remove specific secret only
pass rm agents/old-agent/service/token
```

## Core Operations

### Retrieve a Secret

```bash
# First line is the password/secret
pass show <path>

# Examples:
pass show agents/orchestrator/github/token
pass show services/aws/production/access-key

# Extract just the password (first line only)
pass show agents/orchestrator/github/token | head -1

# Store in variable (never echo or log)
SECRET=$(pass show agents/orchestrator/github/token | head -1)
```

### Store a New Secret

```bash
# Interactive entry (avoids history/context leakage)
pass insert <path>

# Non-interactive (use for agent automation — pipe via stdin)
echo "$SECRET_VALUE" | pass insert --force <path>

# Multi-line secrets (API key + secret on separate lines)
pass insert --force <path> <<EOF
$API_KEY
$API_SECRET
EOF
```

### Update an Existing Secret

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

# Generate and show
pass generate <path> 32 && pass show <path>

# Generate without symbols (for systems that reject special chars)
pass generate -n <path> 32
```

### List All Secrets

```bash
pass ls                    # Full tree
pass ls agents/            # All agent namespaces
pass ls homelab/           # Subtree
pass grep "pattern"        # Search by name
```

### Remove a Secret

```bash
pass rm <path>
pass rm -r <directory>     # Remove directory
```

## Permission Escalation Rules (MANDATORY)

Agents MUST request permission before accessing secrets outside their namespace.

### What Requires Permission

| Action | Required |
|--------|----------|
| Accessing `personal/` namespace | User permission |
| Accessing `agents/<other-agent>/` | User permission |
| Accessing `services/` not in agent's authorized list | User permission |
| Adding new secrets to `services/` | User permission |
| Removing any secret | User permission |
| Listing contents of `personal/` | User permission |

### Permission Request Pattern

When an agent needs a secret outside its namespace:

```
PERMISSION REQUEST:
Agent: <agent-name>
Action: Retrieve secret
Path: personal/ssh/github-personal
Reason: <why this secret is needed>
Scope: <how the secret will be used>
```

### Authorization Flow

```bash
# Agent discovers it needs a secret outside its namespace
NEEDED_PATH="personal/ssh/github-personal"

# Check if agent has authorized access
AGENT_AUTH_FILE="$HOME/.config/pass/agents/<agent-name>/authorized.conf"
if ! grep -q "^$NEEDED_PATH$" "$AGENT_AUTH_FILE" 2>/dev/null; then
    # Request permission from user
    echo "PERMISSION REQUIRED: Access to $NEEDED_PATH"
    echo "Agent: <agent-name>"
    echo "Reason: <explanation>"
    # Wait for user approval before proceeding
    # DO NOT proceed without explicit approval
fi
```

### Authorized Access File Format

Create `~/.config/pass/agents/<agent-name>/authorized.conf`:

```
# Paths this agent is authorized to access (one per line)
services/aws/production/access-key
services/github/personal-access-token
services/homelab/ai/chatgpt/api-key
```

## Anti-Leak Guarantees (MANDATORY)

These rules are NON-NEGOTIABLE. Violating them leaks secrets.

### Rule 1: Never Log Secret Values

```bash
# BAD: Secret appears in agent logs
echo "Retrieved token: $(pass show agents/orchestrator/github/token)"

# BAD: Secret appears in debug output
logger "Token value: $TOKEN"

# GOOD: Log path only, never value
echo "Retrieved secret from: agents/orchestrator/github/token"
```

### Rule 2: Never Echo Secrets to stdout/stderr

```bash
# BAD: Secret printed to terminal/log
pass show agents/orchestrator/github/token

# BAD: Variable echoed
echo "$SECRET"

# GOOD: Use variable without echoing
TOKEN=$(pass show agents/orchestrator/github/token | head -1)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com
```

### Rule 3: Never Pass Secrets as Command Arguments

```bash
# BAD: Secret visible in ps output
curl -H "Authorization: Bearer $(pass show api/token)" https://api.example.com

# GOOD: Secret via env var (invisible to ps)
TOKEN=$(pass show api/token | head -1) curl -H "Authorization: Bearer $TOKEN" https://api.example.com
```

### Rule 4: Never Write Secrets to Temporary Files

```bash
# BAD: Secret on disk in plaintext
pass show agents/orchestrator/github/token > /tmp/token.txt
curl -H "Authorization: Bearer $(cat /tmp/token.txt)" https://api.example.com
rm /tmp/token.txt  # File may still exist in backup/snapshot

# GOOD: Secret stays in memory only
TOKEN=$(pass show agents/orchestrator/github/token | head -1)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com
unset TOKEN  # Clear when done
```

### Rule 5: Never Commit Secrets to Git

```bash
# BAD: .env file with real secrets
echo "API_KEY=$(pass show api/key)" > .env
git add .env  # LEAKED

# GOOD: Template only
echo "API_KEY=<your-key-here>" > .env.template
git add .env.template  # Safe
```

### Rule 6: Never Share Secrets Across Context Windows

```bash
# BAD: Secret stored in agent context/memory
# (Agent writes secret to a file that persists across sessions)

# GOOD: Secret retrieved fresh each session
SECRET=$(pass show agents/<agent>/service/key | head -1)
# Use immediately, don't persist
```

### Rule 7: Never Use `set -x` Without Filtering

```bash
# BAD: set -x logs all variable expansions
set -x
TOKEN=$(pass show api/token | head -1)  # Logged to trace

# GOOD: Filter sensitive output
set -x
# Add to BASH_ENV or trap to filter secrets from trace
export BASH_ENV="/tmp/filter-secrets.sh"
```

### Rule 8: Never Leave Secrets in Shell History

```bash
# BAD: Secret typed directly
pass insert agents/orchestrator/github/token
# Then typed: ghp_xxxxxxxxxxxx

# GOOD: Use pipe to avoid history
echo "$TOKEN" | pass insert --force agents/orchestrator/github/token
```

## One-Off Secret Storage (Isolated Leakage Prevention)

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

# Usage in agent workflow
isolated_store=$(setup_isolated_pass)
echo "$DISCOVERED_API_KEY" | pass insert --force temp/service-key
# ... use the secret ...
# Cleanup happens automatically via trap
```

### Per-Session Secret Namespace

For multi-step agent workflows, use a session-scoped namespace:

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

| Item | Track? | Reason |
|------|--------|--------|
| Secret paths/directories | Yes | Documents what exists |
| Secret values | NEVER | Permanent leakage |
| Agent namespace structure | Yes | Documents agent organization |
| `_agent-sessions/` | NO | Ephemeral, should be gitignored |
| `.gpg-id` | Yes | Required for pass to function |

### Safe Commit Messages

```bash
# GOOD: Describes what changed, not the value
git commit -m "feat(secrets): add agents/language-coder/npm/auth-token"

# GOOD: Describes removal
git commit -m "chore(secrets): remove deprecated agents/old-agent namespace"

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
git bundle verify ~/pass-backup-$(date +%m%d).bundle
```

## Agent Autonomous Flow Patterns

### Pattern 1: Secret Injection into Commands

```bash
# Safe: Secret never appears in process list or logs
TOKEN=$(pass show agents/orchestrator/github/token | head -1)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/data
unset TOKEN
```

### Pattern 2: Service Setup with Secret Retrieval

```bash
configure_service() {
    local service=$1
    local key_path=$2
    
    # Verify authorization first
    if ! check_authorization "$key_path"; then
        echo "PERMISSION REQUIRED: $key_path" >&2
        return 1
    fi
    
    # Retrieve from pass
    local secret
    secret=$(pass show "$key_path" | head -1)
    
    # Write to service config file (not env, not inline)
    cat > "$HOME/.config/$service/config.env" <<EOF
API_KEY=$secret
EOF
    
    # Set restrictive permissions
    chmod 600 "$HOME/.config/$service/config.env"
    
    # Clear secret from memory
    unset secret
}
```

### Pattern 3: Secret Rotation

```bash
rotate_and_store() {
    local path=$1
    local new_value=$2
    
    # Verify this agent can modify this path
    if ! check_write_authorization "$path"; then
        echo "PERMISSION REQUIRED: Rotate $path" >&2
        return 1
    fi
    
    # Store new value
    echo "$new_value" | pass insert --force "$path"
    
    # Verify
    local stored
    stored=$(pass show "$path" | head -1)
    [[ "$stored" == "$new_value" ]] && echo "Rotation verified" || echo "Rotation failed"
    
    # Clear from memory
    unset new_value stored
}
```

### Pattern 4: Multi-Line Secret Handling

```bash
# Some services need key=value pairs or JSON
pass show service/config | while IFS='=' read -r key value; do
    export "$key=$value"
done

# Or parse specific lines
API_KEY=$(pass show service/creds | sed -n '1p')
API_SECRET=$(pass show service/creds | sed -n '2p')

# Clear after use
unset API_KEY API_SECRET
```

## Common Mistakes

### Leaking via Process Arguments

```bash
# BAD: Secret visible in ps
curl -H "Authorization: Bearer $(pass show api/token)" https://api.example.com

# GOOD: Secret via env var (invisible to ps)
TOKEN=$(pass show api/token | head -1) curl -H "Authorization: Bearer $TOKEN" https://api.example.com
```

### Leaking via Command Substitution in Echo

```bash
# BAD: If set -x is on, secret appears in trace
echo "Token is: $(pass show api/token)"

# GOOD: Capture to variable first, never echo
TOKEN=$(pass show api/token | head -1)
# Use $TOKEN without echoing it directly
```

### Not Using `--force` in Scripts

```bash
# BAD: Hangs waiting for interactive input in scripts
pass insert secret/path

# GOOD: Non-interactive for automation
echo "$VALUE" | pass insert --force secret/path
```

### Accessing Personal Secrets Without Permission

```bash
# BAD: Agent accesses personal namespace without asking
SECRET=$(pass show personal/ssh/github-personal | head -1)

# GOOD: Agent requests permission first
echo "PERMISSION REQUIRED: Access to personal/ssh/github-personal"
echo "Reason: Need SSH key for repository access"
# Wait for user approval
```

## Cross-Harness Notes

- Pass store is shared across all agents/harnesses via `~/.password-store/`
- GPG key must be available to the running agent
- For headless agents, ensure `GPG_AGENT_INFO` or `gpg-agent` is running
- One-off isolated stores are per-session and don't affect the shared store
- Agent authorization files live in `~/.config/pass/agents/<agent-name>/authorized.conf`
