# Pass Store Post-Migration Reference

## Quick Reference for Agents

After migration, use these paths to find secrets:

### Agent-Specific Secrets

```bash
# Your own agent namespace (auto-authorized)
pass show agents/<your-agent-name>/<service>/<key>

# Example for language-coder agent
pass show agents/language-coder/github/token | head -1
```

### Shared Service Secrets

```bash
# AI Services
pass show services/ai/chatgpt/api-key | head -1
pass show services/ai/gemini/api-key | head -1
pass show services/ai/nvidia/api-key | head -1
pass show services/ai/openrouter/msty-api-key | head -1
pass show services/ai/openclaw/github-pat | head -1

# Developer Services
pass show services/developers/github/access-token | head -1
pass show services/developers/github/dotfiles-pat | head -1

# Communication
pass show services/communication/slack/api-token | head -1
pass show services/communication/slack/webhook | head -1

# Containers
pass show services/containers/docker/credentials | head -1
pass show services/containers/quay/cli | head -1

# Storage
pass show services/storage/minio/access-key | head -1
pass show services/storage/synology/s3/credentials | head -1

# Home Automation
pass show services/home-automation/home-assistant/backup-key | head -1
pass show services/home-automation/mqtt | head -1

# Media
pass show services/media/lidarr/api-key | head -1
pass show services/media/radarr/api-key | head -1

# Cloud
pass show services/cloud/oracle/credentials | head -1
pass show services/cloud/backblaze/s3/credentials | head -1
```

### Infrastructure Secrets (Homelab)

```bash
# Networking
pass show infrastructure/dns/cloudflare/api-key | head -1
pass show infrastructure/vpn/privado | head -1
pass show infrastructure/network/omada/k3s | head -1

# Proxmox
pass show infrastructure/proxmox/api | head -1

# Database
pass show infrastructure/database/mysql/root-credentials | head -1

# SSO
pass show infrastructure/sso/auth0/k3s | head -1
```

### Personal Secrets (Requires Permission)

```bash
# These require user approval
pass show personal/usenet/easynews.com | head -1
pass show personal/email/lovell.felix@gmail.com | head -1
```

## Directory Structure

```
~/.password-store/
├── agents/                    # Agent-specific (scoped access)
│   ├── orchestrator/
│   ├── language-coder/
│   ├── sre-debugger/
│   └── life-agent/
├── services/                  # Shared service credentials
│   ├── ai/                    # AI API keys
│   ├── cloud/                 # Cloud provider creds
│   ├── containers/            # Container registry
│   ├── communication/         # Slack, email, webhooks
│   ├── developers/            # GitHub, dev tools
│   ├── home-automation/       # Home Assistant, MQTT
│   ├── media/                 # Arr apps, Obsidian
│   ├── projects/              # Project-specific
│   ├── storage/               # MinIO, Synology, Ceph
│   └── billing/               # Stripe, payments
├── infrastructure/            # Homelab infrastructure
│   ├── age/
│   ├── apps/                  # Self-hosted apps
│   ├── database/
│   ├── dns/
│   ├── network/
│   ├── proxmox/
│   ├── sso/
│   └── vpn/
├── personal/                  # User-only (requires permission)
│   ├── email/
│   └── usenet/
└── _agent-sessions/           # Ephemeral (gitignored)
```

## Permission Rules

| Namespace | Access Level |
|-----------|--------------|
| `agents/<your-agent>/` | Auto-authorized |
| `services/` | Check authorized.conf |
| `infrastructure/` | Check authorized.conf |
| `personal/` | Always requires user permission |
| `_agent-sessions/` | Creating agent only |

## Adding New Secrets

```bash
# Agent-specific
echo "$TOKEN" | pass insert --force agents/<your-agent>/<service>/<key>

# Shared service (requires permission)
echo "$TOKEN" | pass insert --force services/<category>/<service>/<key>

# Infrastructure (requires permission)
echo "$TOKEN" | pass insert --force infrastructure/<component>/<key>
```

## Listing Available Secrets

```bash
# List all
pass ls

# List by category
pass ls services/ai/
pass ls infrastructure/
pass ls personal/

# Search by name
pass grep "api-key"
pass grep "token"
```
