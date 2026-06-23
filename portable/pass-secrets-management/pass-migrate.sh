#!/usr/bin/env bash
# pass-migrate.sh — Reorganize pass store for agent-friendly namespace structure
# Handles duplicates and merges correctly
#
# Usage:
#   ./pass-migrate.sh --dry-run    # Preview changes without moving anything
#   ./pass-migrate.sh --execute    # Actually move secrets
#   ./pass-migrate.sh --rollback   # Undo last migration (from backup)

set -euo pipefail

PASS_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
BACKUP_DIR="$HOME/.password-store-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=true
EXECUTE=false
ROLLBACK=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            EXECUTE=false
            shift
            ;;
        --execute)
            DRY_RUN=false
            EXECUTE=true
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--dry-run|--execute|--rollback]" >&2
            exit 1
            ;;
    esac
done

# Migration mapping: old_path -> new_path
# Format: "old_path|new_path|type"
# Types: simple, merge_file_to_dir, merge_rename
declare -a MIGRATIONS=(
    # === PHASE 1: Simple moves (no conflicts) ===
    
    # Infrastructure
    "homelab/age/key|infrastructure/age/key|simple"
    "homelab/apps/botkube/slack-token-string|infrastructure/apps/botkube/slack-token|simple"
    "homelab/apps/infisical|infrastructure/apps/infisical|simple"
    "homelab/apps/kured/notify-uri|infrastructure/apps/kured/notify-uri|simple"
    "homelab/apps/paperless/credentials|infrastructure/apps/paperless/credentials|simple"
    "homelab/apps/pocketid|infrastructure/apps/pocketid|simple"
    "homelab/apps/prometheus|infrastructure/apps/prometheus|simple"
    "homelab/database/mysql/backup-credentials|infrastructure/database/mysql/backup-credentials|simple"
    "homelab/database/mysql/phpmyadmin-credentials|infrastructure/database/mysql/phpmyadmin-credentials|simple"
    "homelab/database/mysql/root-credentials|infrastructure/database/mysql/root-credentials|simple"
    "homelab/dns/cloudflare/api-key-string|infrastructure/dns/cloudflare/api-key|simple"
    "homelab/dns/cloudflare/ddns|infrastructure/dns/cloudflare/ddns|simple"
    "homelab/dns/cloudflare/email-string|infrastructure/dns/cloudflare/email|simple"
    "homelab/dns/cloudflare/tunnel/k3s|infrastructure/dns/cloudflare/tunnel/k3s|simple"
    "homelab/network/omada/k3s|infrastructure/network/omada/k3s|simple"
    "homelab/proxmox/api|infrastructure/proxmox/api|simple"
    "homelab/proxmox/cluster-api-users/capmox|infrastructure/proxmox/cluster-api-users/capmox|simple"
    "homelab/proxmox/cluster-api-users/image-builder|infrastructure/proxmox/cluster-api-users/image-builder|simple"
    "homelab/sso/auth0/k3s|infrastructure/sso/auth0/k3s|simple"
    "homelab/vpn/privado|infrastructure/vpn/privado|simple"
    
    # Services - AI
    "homelab/ai/chatgpi/nvim-access-key-string|services/ai/chatgpt/nvim-access-key|simple"
    "homelab/ai/chatgpi/raycast-access-key-string|services/ai/chatgpt/raycast-access-key|simple"
    "homelab/ai/gemini/api-key|services/ai/gemini/api-key|simple"
    "homelab/ai/gemini/hass/api-key|services/ai/gemini/hass-api-key|simple"
    "homelab/ai/hermes-agent/hass-token|services/ai/hermes-agent/hass-token|simple"
    "homelab/ai/openrouter/msty_api_key|services/ai/openrouter/msty-api-key|simple"
    "homelab/ai/openrouter/roocode_api_key|services/ai/openrouter/roocode-api-key|simple"
    "homelab/openclaw/github-pat|services/ai/openclaw/github-pat|simple"
    "work/ai/claude/authcode|services/ai/claude/authcode|simple"
    
    # Services - Containers
    "homelab/docker.com/credentials|services/containers/docker/credentials|simple"
    "homelab/docker.com/secret-string|services/containers/docker/secret|simple"
    "homelab/quay.io/cli|services/containers/quay/cli|simple"
    "homelab/quay.io/personal|services/containers/quay/personal|simple"
    "homelab/quay.io/secret-string|services/containers/quay/secret|simple"
    
    # Services - Communication
    "homelab/slack/api-token-string|services/communication/slack/api-token|simple"
    "homelab/slack/webhook-string|services/communication/slack/webhook|simple"
    "homelab/mail/mailgun/smtp-credentials|services/communication/mailgun/smtp-credentials|simple"
    
    # Services - Developers
    "homelab/github/access_token_string|services/developers/github/access-token|simple"
    "homelab/github/dotfiles_rw_pat|services/developers/github/dotfiles-pat|simple"
    "homelab/tools/insomnia|services/developers/insomnia|simple"
    "homelab/tools/netlify/raycast-api-key|services/developers/netlify/raycast-api-key|simple"
    
    # Services - Media
    "homelab/apps/lidarr/api-key-string|services/media/lidarr/api-key|simple"
    "homelab/apps/radarr/api-key-string|services/media/radarr/api-key|simple"
    "homelab/apps/sonarr/api-key-string|services/media/sonarr/api-key|simple"
    "homelab/apps/whisparr/api-key-string|services/media/whisparr/api-key|simple"
    "homelab/apps/prowlarr/api-key-string|services/media/prowlarr/api-key|simple"
    "homelab/apps/obsidian/couchdb|services/media/obsidian/couchdb|simple"
    "homelab/apps/obsidian/encryption-key|services/media/obsidian/encryption-key|simple"
    
    # Services - Home Automation (simple moves)
    "homelab/apps/mqtt|services/home-automation/mqtt|simple"
    
    # Services - Projects
    "homelab/gbuzz/android/google-play-store/service-account|services/projects/gbuzz/google-play-store/service-account|simple"
    "homelab/gbuzz/android/gradle/keystore|services/projects/gbuzz/gradle/keystore|simple"
    
    # Services - Storage
    "homelab/storage/ceph/credentials|services/storage/ceph/credentials|simple"
    "homelab/storage/minio/access-key-string|services/storage/minio/access-key|simple"
    "homelab/storage/minio/access-secret-key-string|services/storage/minio/access-secret-key|simple"
    "homelab/storage/minio/console-credentials|services/storage/minio/console-credentials|simple"
    "homelab/storage/minio/credentials|services/storage/minio/credentials|simple"
    "homelab/storage/minio/endpoint-string|services/storage/minio/endpoint|simple"
    "homelab/storage/minio/prometheus-token-string|services/storage/minio/prometheus-token|simple"
    "homelab/storage/synology/csi|services/storage/synology/csi|simple"
    "homelab/storage/synology/s3/app-bkup|services/storage/synology/s3/app-backup|simple"
    "homelab/storage/synology/s3/credentials|services/storage/synology/s3/credentials|simple"
    "homelab/storage/synology/s3/photo-bkup|services/storage/synology/s3/photo-backup|simple"
    
    # Services - Cloud
    "homelab/storage/backblaze/s3/credentials|services/cloud/backblaze/s3/credentials|simple"
    "homelab/storage/oracle/console|services/cloud/oracle/console|simple"
    "homelab/storage/oracle/credentials|services/cloud/oracle/credentials|simple"
    
    # Services - Billing
    "homelab/clients/hm/stripe|services/billing/stripe/hm|simple"
    
    # Personal
    "homelab/misc/newshosting/easynews.com|personal/usenet/easynews.com|simple"
    "homelab/misc/newshosting/frugalusenet.com|personal/usenet/frugalusenet.com|simple"
    "homelab/misc/newshosting/nzbfinder.ws|personal/usenet/nzbfinder.ws|simple"
    "homelab/misc/newshosting/nzbgeek.info|personal/usenet/nzbgeek.info|simple"
    "homelab/misc/newshosting/nzbindex.com|personal/usenet/nzbindex.com|simple"
    
    # === PHASE 2: Merges (file → dir, or rename) ===
    
    # NVIDIA merge (fix typo dir + combine)
    "homelab/nvidia/api-key|services/ai/nvidia/api-key|simple"
    "homelab/nividia/kimi-k2-api-key|services/ai/nvidia/kimi-k2-api-key|simple"
    "homelab/nividia/openclaw-api-key|services/ai/nvidia/openclaw-api-key|simple"
    
    # Home Assistant merge (file → dir)
    "homelab/apps/home-assistant|services/home-automation/home-assistant/credentials|merge_file_to_dir"
    "homelab/apps/home-assistant/backup-encryption-key|services/home-automation/home-assistant/backup-key|simple"
    "homelab/apps/home-assistant/raycast-access-token-string|services/home-automation/home-assistant/raycast-token|simple"
    
    # Atuin merge (rename for clarity)
    "homelab/apps/atuin|services/home-automation/atuin/self-hosted|merge_rename"
    
    # VPN merge (file + dir → dir)
    "homelab/vpn/blvtx-vpn|infrastructure/vpn/blvtx-vpn/credentials|merge_file_to_dir"
    "homelab/vpn/blvtx-vpn/openvpn-tun|infrastructure/vpn/blvtx-vpn/openvpn-tun|simple"
)

# Skipped entries (require manual review)
declare -a SKIPPED=(
    "homelab/vpn/bltx-vpn|Corrupted (can't decrypt)|Review manually"
)

log() {
    local color="$1"
    local msg="$2"
    case "$color" in
        green)  echo -e "\033[0;32m✓ $msg\033[0m" ;;
        yellow) echo -e "\033[0;33m→ $msg\033[0m" ;;
        red)    echo -e "\033[0;31m✗ $msg\033[0m" ;;
        blue)   echo -e "\033[0;34m  $msg\033[0m" ;;
        cyan)   echo -e "\033[0;36m  $msg\033[0m" ;;
    esac
}

backup_store() {
    log yellow "Creating backup at $BACKUP_DIR"
    if [[ "$DRY_RUN" == false ]]; then
        cp -r "$PASS_DIR" "$BACKUP_DIR"
        log green "Backup created"
    else
        log blue "[DRY RUN] Would create backup at $BACKUP_DIR"
    fi
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$dir"
        fi
    fi
}

move_secret() {
    local old_path="$1"
    local new_path="$2"
    local type="$3"
    
    local old_file="$PASS_DIR/${old_path}.gpg"
    local new_file="$PASS_DIR/${new_path}.gpg"
    local new_dir
    new_dir=$(dirname "$new_file")
    
    # Check if source exists
    if [[ ! -f "$old_file" ]]; then
        log red "Source not found: $old_path"
        return 1
    fi
    
    # Check if destination already exists (unless it's a merge)
    if [[ -f "$new_file" && "$type" != "merge_file_to_dir" ]]; then
        log red "Destination exists: $new_path"
        return 1
    fi
    
    case "$type" in
        simple)
            if [[ "$DRY_RUN" == true ]]; then
                log blue "[DRY RUN] $old_path -> $new_path"
            else
                ensure_dir "$new_dir"
                mv "$old_file" "$new_file"
                log green "$old_path -> $new_path"
            fi
            ;;
        merge_file_to_dir)
            # Source is a file, destination is a file inside a new directory
            # The directory might already have other files
            if [[ "$DRY_RUN" == true ]]; then
                log cyan "[DRY RUN] MERGE $old_path -> $new_path (file → dir)"
            else
                ensure_dir "$new_dir"
                if [[ -f "$new_file" ]]; then
                    # Destination exists, need to handle conflict
                    local backup="${new_file}.bak.$(date +%s)"
                    mv "$new_file" "$backup"
                    mv "$old_file" "$new_file"
                    log yellow "Merged with backup: $backup"
                else
                    mv "$old_file" "$new_file"
                fi
                log green "MERGE: $old_path -> $new_path"
            fi
            ;;
        merge_rename)
            # Rename file as part of merge
            if [[ "$DRY_RUN" == true ]]; then
                log cyan "[DRY RUN] RENAME $old_path -> $new_path"
            else
                ensure_dir "$new_dir"
                mv "$old_file" "$new_file"
                log green "RENAME: $old_path -> $new_path"
            fi
            ;;
    esac
}

cleanup_empty_dirs() {
    if [[ "$DRY_RUN" == true ]]; then
        log blue "[DRY RUN] Would remove empty directories under homelab/ and work/"
        return
    fi
    
    log yellow "Cleaning up empty directories..."
    find "$PASS_DIR/homelab" -type d -empty -delete 2>/dev/null || true
    find "$PASS_DIR/work" -type d -empty -delete 2>/dev/null || true
    log green "Empty directories cleaned"
}

print_summary() {
    local total=${#MIGRATIONS[@]}
    local skipped=${#SKIPPED[@]}
    
    echo ""
    echo "========================================="
    echo "  Migration Summary"
    echo "========================================="
    echo ""
    echo "Total migrations: $total"
    echo "Skipped (manual review): $skipped"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "Mode: DRY RUN (no changes made)"
        echo ""
        echo "To execute, run:"
        echo "  $0 --execute"
    else
        echo "Mode: EXECUTED"
        echo ""
        echo "Backup location: $BACKUP_DIR"
        echo ""
        echo "To rollback, run:"
        echo "  $0 --rollback"
    fi
    echo ""
}

print_skipped() {
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo ""
        echo "========================================="
        echo "  Skipped Entries (Manual Review Needed)"
        echo "========================================="
        echo ""
        for entry in "${SKIPPED[@]}"; do
            IFS='|' read -r path reason action <<< "$entry"
            echo "  $path"
            echo "    Reason: $reason"
            echo "    Action: $action"
            echo ""
        done
    fi
}

rollback_migration() {
    # Find the most recent backup
    local latest_backup
    latest_backup=$(ls -td "$HOME"/.password-store-backup-* 2>/dev/null | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        log red "No backup found for rollback"
        exit 1
    fi
    
    log yellow "Rolling back from: $latest_backup"
    
    if [[ "$DRY_RUN" == true ]]; then
        log blue "[DRY RUN] Would restore from $latest_backup"
    else
        rm -rf "$PASS_DIR"
        cp -r "$latest_backup" "$PASS_DIR"
        log green "Restored from backup"
    fi
}

# Main execution
echo "Pass Store Migration (Deduplicated)"
echo "===================================="
echo ""

if [[ "$ROLLBACK" == true ]]; then
    rollback_migration
    exit 0
fi

backup_store

echo ""
echo "Applying migrations..."
echo ""

success=0
failed=0

for migration in "${MIGRATIONS[@]}"; do
    IFS='|' read -r old_path new_path type <<< "$migration"
    if move_secret "$old_path" "$new_path" "$type"; then
        success=$((success + 1))
    else
        failed=$((failed + 1))
    fi
done

cleanup_empty_dirs

echo ""
echo "Results: $success succeeded, $failed failed"

print_summary
print_skipped
