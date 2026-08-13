#!/usr/bin/env bash
set -euo pipefail

# rotate-agent-key.sh — generic SSH key setup & rotation for any remote account.
#
# Creates or rotates an SSH key for <user>@<host>, storing it in 3 places:
#   disk:   ~/.ssh/agents/<host>/<user>/id_<type>
#   pass:   infrastructure/ssh/<host>/<user>/id_<type>
#   remote: ~<user>/.ssh/authorized_keys (pushed via root@<host>)
#
# Usage:
#   ./rotate-agent-key.sh <host> <user>               # rotate existing
#   ./rotate-agent-key.sh <host> <user> --create       # first-time setup
#   ./rotate-agent-key.sh jarvis-claude claude         # claude@jarvis-claude
#   ./rotate-agent-key.sh 10.0.10.48 deploy            # IP-based
#
# Options:
#   --create          First-time setup (skip backup)
#   --key-type TYPE   Algorithm: ed25519|rsa|ecdsa (default: ed25519)
#   --root-user USER  SSH user to push authorized_keys (default: root)
#   --backup-dir DIR  Custom backup directory
#   --dry-run         Preview without making changes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_BASEDIR="${HOME}/.ssh/agents"
PASS_BASE="infrastructure/ssh"

REMOTE_HOST="${1:-}"
REMOTE_USER="${2:-}"
KEY_TYPE="${KEY_TYPE:-ed25519}"
ROOT_USER="${ROOT_USER:-root}"
BACKUP_DIR="${BACKUP_DIR:-}"
DRY_RUN=false
CREATE_MODE=false

usage() {
    echo "Usage: $0 <host> <user> [options]"
    echo ""
    echo "Arguments:"
    echo "  <host>           Remote hostname or IP"
    echo "  <user>           Remote username"
    echo ""
    echo "Options:"
    echo "  --create         First-time setup (skip backup)"
    echo "  --key-type TYPE  Key algorithm (default: ed25519)"
    echo "  --root-user USER Root SSH user (default: root)"
    echo "  --backup-dir DIR Custom backup path"
    echo "  --dry-run        Preview only, no changes"
    exit 1
}

[[ $# -ge 2 ]] || usage
shift 2

while [[ $# -gt 0 ]]; do
    case "$1" in
        --create) CREATE_MODE=true; shift ;;
        --key-type) KEY_TYPE="$2"; shift 2 ;;
        --root-user) ROOT_USER="$2"; shift 2 ;;
        --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) usage ;;
    esac
done

KEY_DIR="$KEY_BASEDIR/$REMOTE_HOST/$REMOTE_USER"
KEY_PATH="$KEY_DIR/id_$KEY_TYPE"
PASS_PATH="$PASS_BASE/$REMOTE_HOST/$REMOTE_USER/id_$KEY_TYPE"
PASS_PATH_PUB="$PASS_BASE/$REMOTE_HOST/$REMOTE_USER/id_$KEY_TYPE.pub"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
: "${BACKUP_DIR:=$KEY_DIR/backup}"

log()  { echo "[rotate] $(date '+%H:%M:%S') $*"; }
err()  { echo "[rotate] ERROR: $*" >&2; exit 1; }

run() {
    if $DRY_RUN; then echo "[DRY-RUN] $*"; else "$@"; fi
}

[[ -n "$REMOTE_HOST" && -n "$REMOTE_USER" ]] || err "Host and user are required"
[[ "$KEY_TYPE" =~ ^(ed25519|rsa|ecdsa)$ ]]  || err "Key type must be ed25519, rsa, or ecdsa"

if $DRY_RUN; then
    log "DRY-RUN — no changes"
    log "  Key:     $KEY_PATH"
    log "  Pass:    $PASS_PATH"
    log "  Remote:  $REMOTE_USER@$REMOTE_HOST (via $ROOT_USER)"
fi

# 1. Backup existing key
if [[ -f "$KEY_PATH" ]]; then
    if $CREATE_MODE; then
        log "Key exists, --create set. Overwriting without backup."
    else
        log "[1/6] Backing up old key to $BACKUP_DIR/backup-$TIMESTAMP/"
        run mkdir -p "$BACKUP_DIR/backup-$TIMESTAMP"
        run cp "$KEY_PATH" "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE"
        run cp "${KEY_PATH}.pub" "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE.pub"
        run chmod 600 "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE"
    fi
else
    log "No existing key at $KEY_PATH — first-time setup"
    CREATE_MODE=true
fi

# 2. Generate new key
log "[2/6] Generating new $KEY_TYPE key..."
run mkdir -p "$(dirname "$KEY_PATH")"
if ! $DRY_RUN; then
    ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -C "$REMOTE_USER@$REMOTE_HOST" -N "" -q
    chmod 600 "$KEY_PATH"
    chmod 644 "${KEY_PATH}.pub"
fi

# 3. Deploy public key to remote (via root)
log "[3/6] Deploying public key to $REMOTE_USER@$REMOTE_HOST..."
if ! $DRY_RUN; then
    PUBKEY=$(cat "${KEY_PATH}.pub")
    ssh "$ROOT_USER@$REMOTE_HOST" "
        mkdir -p /home/$REMOTE_USER/.ssh
        chmod 700 /home/$REMOTE_USER/.ssh
        echo '$PUBKEY' > /home/$REMOTE_USER/.ssh/authorized_keys
        chmod 600 /home/$REMOTE_USER/.ssh/authorized_keys
        chown -R $REMOTE_USER:$REMOTE_USER /home/$REMOTE_USER/.ssh
    " || err "Failed to deploy. Check $ROOT_USER@$REMOTE_HOST SSH access."
fi

# 4. Store private key in pass
log "[4/6] Storing private key in pass ($PASS_PATH)..."
if ! $DRY_RUN; then
    pass mkdir -p "$PASS_BASE/$REMOTE_HOST/$REMOTE_USER" >/dev/null 2>&1 || true
    cat "$KEY_PATH" | pass insert --force --multiline "$PASS_PATH" >/dev/null 2>&1
fi

# 5. Store public key in pass
log "[5/6] Storing public key in pass ($PASS_PATH_PUB)..."
if ! $DRY_RUN; then
    cat "${KEY_PATH}.pub" | pass insert --force --multiline "$PASS_PATH_PUB" >/dev/null 2>&1
fi

# 6. Verify
log "[6/6] Verifying new key..."
if ! $DRY_RUN; then
    if ssh -i "$KEY_PATH" -o BatchMode=yes -o ConnectTimeout=5 \
        "$REMOTE_USER@$REMOTE_HOST" "echo OK" 2>&1; then
        log "=== Rotation complete. Verified: $REMOTE_USER@$REMOTE_HOST ==="
    else
        log "WARNING: Verification failed. Restoring backup..."
        if [[ -f "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE" ]]; then
            cp "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE" "$KEY_PATH"
            cp "$BACKUP_DIR/backup-$TIMESTAMP/id_$KEY_TYPE.pub" "${KEY_PATH}.pub"
            cat "$KEY_PATH" | pass insert --force --multiline "$PASS_PATH" >/dev/null 2>&1
            log "Backup restored."
        fi
        err "Rotation failed — previous key restored"
    fi
else
    log "DRY-RUN complete. Run without --dry-run to apply."
fi
