# Pass Store Reorganization Plan (Deduplicated)

## Duplicate Analysis

| Entry | Issue | Resolution |
|-------|-------|------------|
| `homelab/apps/home-assistant` (file) | Multi-line secret (token, username, deploy_key, database_pass) | Keep as `services/home-automation/home-assistant/credentials` |
| `homelab/apps/home-assistant/` (dir) | Separate keys (backup-encryption-key, raycast-token) | Merge into `services/home-automation/home-assistant/` |
| `homelab/vpn/bltx-vpn` | Corrupted (can't decrypt) | Skip — mark for manual review |
| `homelab/vpn/blvtx-vpn` (file) | VPN credentials (gw, passkey) | Merge into `infrastructure/vpn/blvtx-vpn/credentials` |
| `homelab/vpn/blvtx-vpn/` (dir) | Contains openvpn-tun config | Keep as `infrastructure/vpn/blvtx-vpn/openvpn-tun` |
| `homelab/apps/atuin` | Self-hosted atuin (user: lovellfelix) | Move to `services/home-automation/atuin/self-hosted` |
| `personal/atuin` | Cloud sync atuin (user: lovell.felix@gmail.com) | Keep as `personal/atuin` (no change) |
| `homelab/nvidia/api-key` | NVIDIA API key | Move to `services/ai/nvidia/api-key` |
| `homelab/nividia/kimi-k2-api-key` | Typo dir, separate key | Merge to `services/ai/nvidia/kimi-k2-api-key` |
| `homelab/nividia/openclaw-api-key` | Typo dir, separate key | Merge to `services/ai/nvidia/openclaw-api-key` |

## Target Structure

```
~/.password-store/
├── agents/                          # Agent-specific secrets
│   ├── orchestrator/
│   │   └── github/
│   │       └── token
│   ├── language-coder/
│   │   ├── github/
│   │   │   └── token
│   │   └── npm/
│   │       └── auth-token
│   ├── sre-debugger/
│   │   ├── kubernetes/
│   │   │   └── kubeconfig-token
│   │   └── ssh/
│   │       └── deploy-key
│   └── life-agent/
│       └── email/
│           └── app-password
├── services/                        # Shared service credentials
│   ├── ai/
│   │   ├── chatgpt/
│   │   │   ├── api-key
│   │   │   ├── nvim-access-key
│   │   │   └── raycast-access-key
│   │   ├── gemini/
│   │   │   ├── api-key
│   │   │   └── hass-api-key
│   │   ├── hermes-agent/
│   │   │   └── hass-token
│   │   ├── nvidia/                  # Merged from nvidia/ + nividia/
│   │   │   ├── api-key
│   │   │   ├── kimi-k2-api-key
│   │   │   └── openclaw-api-key
│   │   ├── openclaw/
│   │   │   └── github-pat
│   │   └── openrouter/
│   │       ├── msty-api-key
│   │       └── roocode-api-key
│   ├── cloud/
│   │   ├── backblaze/
│   │   │   └── s3-credentials
│   │   └── oracle/
│   │       ├── console
│   │       └── credentials
│   ├── containers/
│   │   ├── docker/
│   │   │   ├── credentials
│   │   │   └── secret
│   │   └── quay/
│   │       ├── cli
│   │       ├── personal
│   │       └── secret
│   ├── communication/
│   │   ├── mailgun/
│   │   │   └── smtp-credentials
│   │   └── slack/
│   │       ├── api-token
│   │       └── webhook
│   ├── developers/
│   │   ├── github/
│   │   │   ├── access-token
│   │   │   └── dotfiles-pat
│   │   ├── insomnia/
│   │   └── netlify/
│   │       └── raycast-api-key
│   ├── home-automation/
│   │   ├── atuin/
│   │   │   └── self-hosted         # From homelab/apps/atuin
│   │   ├── home-assistant/
│   │   │   ├── credentials          # From homelab/apps/home-assistant (file)
│   │   │   ├── backup-key           # From homelab/apps/home-assistant/backup-encryption-key
│   │   │   └── raycast-token        # From homelab/apps/home-assistant/raycast-access-token-string
│   │   └── mqtt/
│   ├── media/
│   │   ├── lidarr/
│   │   │   └── api-key
│   │   ├── obsidian/
│   │   │   ├── couchdb
│   │   │   └── encryption-key
│   │   ├── prowlarr/
│   │   │   └── api-key
│   │   ├── radarr/
│   │   │   └── api-key
│   │   ├── sonarr/
│   │   │   └── api-key
│   │   └── whisparr/
│   │       └── api-key
│   ├── projects/
│   │   └── gbuzz/
│   │       ├── google-play-store/
│   │       │   └── service-account
│   │       └── gradle/
│   │           └── keystore
│   ├── storage/
│   │   ├── ceph/
│   │   │   └── credentials
│   │   ├── minio/
│   │   │   ├── access-key
│   │   │   ├── access-secret-key
│   │   │   ├── console-credentials
│   │   │   ├── credentials
│   │   │   ├── endpoint
│   │   │   └── prometheus-token
│   │   └── synology/
│   │       ├── csi
│   │       └── s3/
│   │           ├── app-backup
│   │           ├── credentials
│   │           └── photo-backup
│   └── billing/
│       └── stripe/
│           └── hm
├── infrastructure/                  # Homelab infrastructure
│   ├── age/
│   │   └── key
│   ├── apps/
│   │   ├── botkube/
│   │   │   └── slack-token
│   │   ├── infisical
│   │   ├── kured/
│   │   │   └── notify-uri
│   │   ├── paperless/
│   │   │   └── credentials
│   │   ├── pocketid
│   │   └── prometheus
│   ├── database/
│   │   └── mysql/
│   │       ├── backup-credentials
│   │       ├── phpmyadmin-credentials
│   │       └── root-credentials
│   ├── dns/
│   │   └── cloudflare/
│   │       ├── api-key
│   │       ├── ddns
│   │       ├── email
│   │       └── tunnel/
│   │           └── k3s
│   ├── network/
│   │   └── omada/
│   │       └── k3s
│   ├── proxmox/
│   │   ├── api
│   │   └── cluster-api-users/
│   │       ├── capmox
│   │       └── image-builder
│   ├── sso/
│   │   └── auth0/
│   │       └── k3s
│   └── vpn/
│       ├── blvtx-vpn/              # Merged from file + dir
│       │   ├── credentials          # From homelab/vpn/blvtx-vpn (file)
│       │   └── openvpn-tun          # From homelab/vpn/blvtx-vpn/openvpn-tun
│       └── privado
├── personal/                        # User-only secrets
│   ├── atuin                       # Cloud sync (no change)
│   ├── email/
│   │   └── lovell.felix@gmail.com
│   └── usenet/
│       ├── easynews.com
│       ├── frugalusenet.com
│       ├── nzbfinder.ws
│       ├── nzbgeek.info
│       └── nzbindex.com
└── _agent-sessions/                 # Ephemeral (gitignored)
```

## Migration Mapping (Deduplicated)

### Simple Moves (No Conflicts)

| # | Current Path | New Path | Notes |
|---|-------------|----------|-------|
| 1 | `homelab/age/key` | `infrastructure/age/key` | |
| 2 | `homelab/ai/chatgpi/nvim-access-key-string` | `services/ai/chatgpt/nvim-access-key` | Fix typo |
| 3 | `homelab/ai/chatgpi/raycast-access-key-string` | `services/ai/chatgpt/raycast-access-key` | Fix typo |
| 4 | `homelab/ai/gemini/api-key` | `services/ai/gemini/api-key` | |
| 6 | `homelab/ai/gemini/hass/api-key` | `services/ai/gemini/hass-api-key` | |
| 7 | `homelab/ai/hermes-agent/hass-token` | `services/ai/hermes-agent/hass-token` | |
| 8 | `homelab/ai/openrouter/msty_api_key` | `services/ai/openrouter/msty-api-key` | |
| 9 | `homelab/ai/openrouter/roocode_api_key` | `services/ai/openrouter/roocode-api-key` | |
| 10 | `homelab/apps/botkube/slack-token-string` | `infrastructure/apps/botkube/slack-token` | |
| 11 | `homelab/apps/infisical` | `infrastructure/apps/infisical` | |
| 12 | `homelab/apps/kured/notify-uri` | `infrastructure/apps/kured/notify-uri` | |
| 13 | `homelab/apps/lidarr/api-key-string` | `services/media/lidarr/api-key` | |
| 14 | `homelab/apps/mqtt` | `services/home-automation/mqtt` | |
| 15 | `homelab/apps/obsidian/couchdb` | `services/media/obsidian/couchdb` | |
| 16 | `homelab/apps/obsidian/encryption-key` | `services/media/obsidian/encryption-key` | |
| 17 | `homelab/apps/paperless/credentials` | `infrastructure/apps/paperless/credentials` | |
| 18 | `homelab/apps/pocketid` | `infrastructure/apps/pocketid` | |
| 19 | `homelab/apps/prometheus` | `infrastructure/apps/prometheus` | |
| 20 | `homelab/apps/prowlarr/api-key-string` | `services/media/prowlarr/api-key` | |
| 21 | `homelab/apps/radarr/api-key-string` | `services/media/radarr/api-key` | |
| 22 | `homelab/apps/sonarr/api-key-string` | `services/media/sonarr/api-key` | |
| 23 | `homelab/apps/whisparr/api-key-string` | `services/media/whisparr/api-key` | |
| 24 | `homelab/clients/hm/stripe` | `services/billing/stripe/hm` | |
| 25 | `homelab/database/mysql/backup-credentials` | `infrastructure/database/mysql/backup-credentials` | |
| 26 | `homelab/database/mysql/phpmyadmin-credentials` | `infrastructure/database/mysql/phpmyadmin-credentials` | |
| 27 | `homelab/database/mysql/root-credentials` | `infrastructure/database/mysql/root-credentials` | |
| 28 | `homelab/dns/cloudflare/api-key-string` | `infrastructure/dns/cloudflare/api-key` | |
| 29 | `homelab/dns/cloudflare/ddns` | `infrastructure/dns/cloudflare/ddns` | |
| 30 | `homelab/dns/cloudflare/email-string` | `infrastructure/dns/cloudflare/email` | |
| 31 | `homelab/dns/cloudflare/tunnel/k3s` | `infrastructure/dns/cloudflare/tunnel/k3s` | |
| 32 | `homelab/docker.com/credentials` | `services/containers/docker/credentials` | |
| 33 | `homelab/docker.com/secret-string` | `services/containers/docker/secret` | |
| 34 | `homelab/gbuzz/android/google-play-store/service-account` | `services/projects/gbuzz/google-play-store/service-account` | |
| 35 | `homelab/gbuzz/android/gradle/keystore` | `services/projects/gbuzz/gradle/keystore` | |
| 36 | `homelab/github/access_token_string` | `services/developers/github/access-token` | |
| 37 | `homelab/github/dotfiles_rw_pat` | `services/developers/github/dotfiles-pat` | |
| 38 | `homelab/mail/mailgun/smtp-credentials` | `services/communication/mailgun/smtp-credentials` | |
| 39 | `homelab/misc/newshosting/easynews.com` | `personal/usenet/easynews.com` | |
| 40 | `homelab/misc/newshosting/frugalusenet.com` | `personal/usenet/frugalusenet.com` | |
| 41 | `homelab/misc/newshosting/nzbfinder.ws` | `personal/usenet/nzbfinder.ws` | |
| 42 | `homelab/misc/newshosting/nzbgeek.info` | `personal/usenet/nzbgeek.info` | |
| 43 | `homelab/misc/newshosting/nzbindex.com` | `personal/usenet/nzbindex.com` | |
| 44 | `homelab/network/omada/k3s` | `infrastructure/network/omada/k3s` | |
| 45 | `homelab/openclaw/github-pat` | `services/ai/openclaw/github-pat` | |
| 46 | `homelab/proxmox/api` | `infrastructure/proxmox/api` | |
| 47 | `homelab/proxmox/cluster-api-users/capmox` | `infrastructure/proxmox/cluster-api-users/capmox` | |
| 48 | `homelab/proxmox/cluster-api-users/image-builder` | `infrastructure/proxmox/cluster-api-users/image-builder` | |
| 49 | `homelab/quay.io/cli` | `services/containers/quay/cli` | |
| 50 | `homelab/quay.io/personal` | `services/containers/quay/personal` | |
| 51 | `homelab/quay.io/secret-string` | `services/containers/quay/secret` | |
| 52 | `homelab/slack/api-token-string` | `services/communication/slack/api-token` | |
| 53 | `homelab/slack/webhook-string` | `services/communication/slack/webhook` | |
| 54 | `homelab/sso/auth0/k3s` | `infrastructure/sso/auth0/k3s` | |
| 55 | `homelab/storage/backblaze/s3/credentials` | `services/cloud/backblaze/s3/credentials` | |
| 56 | `homelab/storage/ceph/credentials` | `services/storage/ceph/credentials` | |
| 57 | `homelab/storage/minio/access-key-string` | `services/storage/minio/access-key` | |
| 58 | `homelab/storage/minio/access-secret-key-string` | `services/storage/minio/access-secret-key` | |
| 59 | `homelab/storage/minio/console-credentials` | `services/storage/minio/console-credentials` | |
| 60 | `homelab/storage/minio/credentials` | `services/storage/minio/credentials` | |
| 61 | `homelab/storage/minio/endpoint-string` | `services/storage/minio/endpoint` | |
| 62 | `homelab/storage/minio/prometheus-token-string` | `services/storage/minio/prometheus-token` | |
| 63 | `homelab/storage/oracle/console` | `services/cloud/oracle/console` | |
| 64 | `homelab/storage/oracle/credentials` | `services/cloud/oracle/credentials` | |
| 65 | `homelab/storage/synology/csi` | `services/storage/synology/csi` | |
| 66 | `homelab/storage/synology/s3/app-bkup` | `services/storage/synology/s3/app-backup` | |
| 67 | `homelab/storage/synology/s3/credentials` | `services/storage/synology/s3/credentials` | |
| 68 | `homelab/storage/synology/s3/photo-bkup` | `services/storage/synology/s3/photo-backup` | |
| 69 | `homelab/tools/insomnia` | `services/developers/insomnia` | |
| 70 | `homelab/tools/netlify/raycast-api-key` | `services/developers/netlify/raycast-api-key` | |
| 71 | `homelab/vpn/privado` | `infrastructure/vpn/privado` | |
| 72 | `work/ai/claude/authcode` | `services/ai/claude/authcode` | |

### Merges (Multiple Sources → One Destination)

| # | Current Paths | New Path | Strategy |
|---|--------------|----------|----------|
| 73 | `homelab/nvidia/api-key` | `services/ai/nvidia/api-key` | Direct move |
| 74 | `homelab/nividia/kimi-k2-api-key` | `services/ai/nvidia/kimi-k2-api-key` | Direct move (fix typo dir) |
| 75 | `homelab/nividia/openclaw-api-key` | `services/ai/nvidia/openclaw-api-key` | Direct move (fix typo dir) |
| 76 | `homelab/apps/home-assistant` (file) | `services/home-automation/home-assistant/credentials` | Rename file → dir entry |
| 77 | `homelab/apps/home-assistant/backup-encryption-key` | `services/home-automation/home-assistant/backup-key` | Move into new dir |
| 78 | `homelab/apps/home-assistant/raycast-access-token-string` | `services/home-automation/home-assistant/raycast-token` | Move into new dir |
| 79 | `homelab/apps/atuin` | `services/home-automation/atuin/self-hosted` | Move + rename |
| 80 | `homelab/vpn/blvtx-vpn` (file) | `infrastructure/vpn/blvtx-vpn/credentials` | Merge file → dir entry |
| 81 | `homelab/vpn/blvtx-vpn/openvpn-tun` | `infrastructure/vpn/blvtx-vpn/openvpn-tun` | Move into new dir |

### Skipped (Requires Manual Review)

| # | Current Path | Issue | Action |
|---|-------------|-------|--------|
| 82 | `homelab/vpn/bltx-vpn` | Corrupted (can't decrypt) | Skip — review manually |

### No Change

| # | Current Path | Notes |
|---|-------------|-------|
| 83 | `personal/atuin` | Cloud sync — different from homelab/apps/atuin |
| 84 | `personal/email/lovell.felix@gmail.com` | Already in correct location |

## Migration Order (Critical)

Due to merges, migrations must run in this order:

1. **Phase 1: Simple moves** (72 items) — No conflicts, move in any order
2. **Phase 2: Directory merges** (items 73-81) — Create target dirs first, then move
3. **Phase 3: Cleanup** — Remove empty source directories
4. **Phase 4: Verify** — Check all entries exist at new paths

## Post-Migration Verification

```bash
# Count total entries before and after
find ~/.password-store -name "*.gpg" -type f | wc -l

# Verify no entries lost
pass ls | grep -c "\.gpg"

# Check new structure
pass ls services/
pass ls infrastructure/
pass ls personal/
pass ls agents/
```
