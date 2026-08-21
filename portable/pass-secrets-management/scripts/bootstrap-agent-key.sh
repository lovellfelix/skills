#!/usr/bin/env bash
# bootstrap-agent-key.sh — one-shot setup (or restore) of the dedicated,
# zero-cache GPG key + GNUPGHOME + `agent/` pass subtree that pass-run.sh
# depends on. Human-operator only — run this yourself, in your own
# terminal. It generates cryptographic material and calls gpg/pass
# directly, neither of which an agent's Bash tool can do (and shouldn't).
#
# What it does:
#   1. Creates $GNUPG_AGENT_HOME (default ~/.gnupg-agent) with
#      default-cache-ttl 0 / max-cache-ttl 0, so every pass-run.sh call
#      prompts pinentry on the physical desktop — no silent reuse.
#   2. If a backup already exists in the main pass store at
#      $AGENT_KEY_BACKUP_PATH (default infrastructure/gpg/agent-secrets-key),
#      imports it — this is the portability path: on a new machine, once
#      your main pass store is synced and your regular GPG key is present,
#      re-running this script restores the SAME agent key, no manual key
#      transfer needed.
#   3. Otherwise generates a new passphrase-protected sign+certify key plus
#      an encryption subkey (you'll be prompted by pinentry twice — once to
#      set the passphrase, once to sign the subkey; a blank passphrase
#      would make the zero-cache setting meaningless, since there'd be
#      nothing to prompt for) and backs it up into the main store at that
#      same path, encrypted to your regular key.
#   4. Runs `pass init -p agent <key-id>` so ~/.password-store/agent/
#      encrypts to the new key.
#
# Idempotent and self-healing: safe to re-run. If $GNUPG_AGENT_HOME already
# has a secret key, generation/restore is skipped; if that key is missing
# an encryption-capable subkey (pass insert would otherwise fail silently),
# one is added and the backup is refreshed.
#
# Env overrides: GNUPG_AGENT_HOME, PASSWORD_STORE_DIR, AGENT_KEY_BACKUP_PATH,
# AGENT_KEY_UID.

set -euo pipefail

log() { echo "[bootstrap-agent-key] $*"; }
die() { echo "[bootstrap-agent-key] ERROR: $*" >&2; exit 1; }

command -v gpg >/dev/null 2>&1 || die "gpg not found on PATH"
command -v pass >/dev/null 2>&1 || die "pass not found on PATH"

GNUPG_AGENT_HOME="${GNUPG_AGENT_HOME:-$HOME/.gnupg-agent}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
BACKUP_PATH="${AGENT_KEY_BACKUP_PATH:-infrastructure/gpg/agent-secrets-key}"
AGENT_KEY_UID="${AGENT_KEY_UID:-agent-secrets}"

[[ -d "$PASSWORD_STORE_DIR" ]] || die "PASSWORD_STORE_DIR ($PASSWORD_STORE_DIR) does not exist — set up your main pass store first"

pinentry_program=""
for candidate in pinentry-mac pinentry-curses pinentry-tty pinentry; do
  if command -v "$candidate" >/dev/null 2>&1; then
    pinentry_program="$(command -v "$candidate")"
    break
  fi
done
[[ -n "$pinentry_program" ]] || die "no pinentry program found on PATH"

log "[1/5] Preparing $GNUPG_AGENT_HOME (zero-cache GNUPGHOME)"
mkdir -p "$GNUPG_AGENT_HOME"
chmod 700 "$GNUPG_AGENT_HOME"
cat > "$GNUPG_AGENT_HOME/gpg-agent.conf" <<EOF
default-cache-ttl 0
max-cache-ttl 0
pinentry-program $pinentry_program
EOF
gpgconf --homedir "$GNUPG_AGENT_HOME" --kill gpg-agent >/dev/null 2>&1 || true

set_ultimate_trust() {
  local fpr="$1"
  echo "${fpr}:6:" | GNUPGHOME="$GNUPG_AGENT_HOME" gpg --import-ownertrust >/dev/null 2>&1 || true
}

has_encryption_capability() {
  local fpr="$1"
  GNUPGHOME="$GNUPG_AGENT_HOME" gpg --list-secret-keys --with-colons "$fpr" 2>/dev/null \
    | awk -F: '($1=="sec"||$1=="ssb"){print $12}' | grep -q 'e'
}

backup_key() {
  local fpr="$1"
  GNUPGHOME="$GNUPG_AGENT_HOME" gpg --armor --export-secret-keys "$fpr" \
    | PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" pass insert --force --multiline "$BACKUP_PATH" >/dev/null
}

need_backup=false
existing_fpr=$(GNUPGHOME="$GNUPG_AGENT_HOME" gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/{print $10; exit}')

if [[ -n "$existing_fpr" ]]; then
  log "[2/5] Agent key already present in $GNUPG_AGENT_HOME ($existing_fpr)"
  key_fpr="$existing_fpr"
  if ! has_encryption_capability "$key_fpr"; then
    log "  ...missing an encryption-capable subkey (pass insert would fail) — adding one now"
    log "  (you'll be prompted for the passphrase you set earlier)"
    GNUPGHOME="$GNUPG_AGENT_HOME" gpg --quick-add-key "$key_fpr" rsa4096 encr never
    need_backup=true
  fi
elif PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" pass show "$BACKUP_PATH" >/dev/null 2>&1; then
  log "[2/5] Restoring agent key from pass backup ($BACKUP_PATH)"
  PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" pass show "$BACKUP_PATH" \
    | GNUPGHOME="$GNUPG_AGENT_HOME" gpg --batch --import
  key_fpr=$(GNUPGHOME="$GNUPG_AGENT_HOME" gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')
  [[ -n "$key_fpr" ]] || die "import from backup succeeded but no secret key found afterward"
  set_ultimate_trust "$key_fpr"
  if ! has_encryption_capability "$key_fpr"; then
    log "  ...restored key is missing an encryption-capable subkey — adding one now"
    GNUPGHOME="$GNUPG_AGENT_HOME" gpg --quick-add-key "$key_fpr" rsa4096 encr never
    need_backup=true
  fi
else
  log "[2/5] No backup found — generating a new dedicated key (you'll be prompted for a passphrase)"
  GNUPGHOME="$GNUPG_AGENT_HOME" gpg --quick-generate-key "$AGENT_KEY_UID" rsa4096 cert,sign never
  key_fpr=$(GNUPGHOME="$GNUPG_AGENT_HOME" gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')
  [[ -n "$key_fpr" ]] || die "key generation succeeded but no secret key found afterward"
  set_ultimate_trust "$key_fpr"
  log "  Adding an encryption subkey (you'll be prompted again — same passphrase)"
  GNUPGHOME="$GNUPG_AGENT_HOME" gpg --quick-add-key "$key_fpr" rsa4096 encr never
  need_backup=true
fi

if $need_backup; then
  has_encryption_capability "$key_fpr" || die "key $key_fpr still has no encryption-capable subkey after remediation"
  log "[3/5] Backing up the key into the main pass store ($BACKUP_PATH), encrypted to your regular key"
  backup_key "$key_fpr"
fi

log "[4/5] Pointing ~/.password-store/agent/ at the agent key ($key_fpr)"
PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" GNUPGHOME="$GNUPG_AGENT_HOME" pass init -p agent "$key_fpr" >/dev/null

log "[5/5] Done."
log "  GNUPGHOME:  $GNUPG_AGENT_HOME (default-cache-ttl 0 / max-cache-ttl 0)"
log "  Key:        $key_fpr"
log "  Backup:     $BACKUP_PATH (in your main store — carries this key to any machine with your regular key)"
log "  Store:      $PASSWORD_STORE_DIR/agent/"
log ""
log "Next: provision a secret, e.g."
log "  echo \"\$VALUE\" | PASSWORD_STORE_DIR=$PASSWORD_STORE_DIR GNUPGHOME=$GNUPG_AGENT_HOME pass insert --force agent/<name>"
log "then use it via scripts/pass-run.sh --secret agent/<name> -- <command...>"
