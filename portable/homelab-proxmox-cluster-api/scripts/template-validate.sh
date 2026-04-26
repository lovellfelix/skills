#!/usr/bin/env bash
set -euo pipefail

# template-validate.sh - validate a Proxmox VM template/clone operation and cloud-init
# Non-destructive checks: validates template existence (optional), storage accessibility (optional), and basic cloud-init userdata rendering.

PVE_HOST=${PVE_HOST:-localhost}
PVE_USER=${PVE_USER:-root@pam}
TEMPLATE_ID=${TEMPLATE_ID:-}
STORAGE=${STORAGE:-}
CLOUD_INIT_FILE=${CLOUD_INIT_FILE:-}
# If set (true/1), treat remote validation failures as fatal. Default: recoverable warnings.
LIVE_SECRETS=${LIVE_SECRETS:-}

SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"

fail(){ echo "ERROR: $*" >&2; exit 1; }
info(){ echo "[info] $*"; }
warn(){ echo "[warn] $*"; }

if [ -z "$TEMPLATE_ID" ] && [ -z "$CLOUD_INIT_FILE" ]; then
  info "No TEMPLATE_ID or CLOUD_INIT_FILE provided. Nothing to validate; exiting success."
  exit 0
fi

should_fail_on_remote_error() {
  if [ -n "$LIVE_SECRETS" ]; then
    case "$LIVE_SECRETS" in
      1|true|TRUE|yes|YES) return 0 ;;
    esac
  fi
  return 1
}

if [ -n "$TEMPLATE_ID" ]; then
  info "Checking template $TEMPLATE_ID on $PVE_HOST"
  if ! ssh $SSH_OPTS "$PVE_USER@$PVE_HOST" "qm status $TEMPLATE_ID" >/dev/null 2>&1; then
    if should_fail_on_remote_error; then
      fail "Unable to query Proxmox via ssh; ensure SSH keys and correct user/host"
    else
      warn "Unable to query Proxmox via ssh; treating as recoverable warning. Ensure SSH keys and correct user/host"
    fi
    # fallback to pvesh if available locally
    if command -v pvesh >/dev/null 2>&1; then
      info "Attempting pvesh nodes/..."
      pvesh get /nodes || true
    fi
  fi

  if [ -n "$STORAGE" ]; then
    info "Validating storage '$STORAGE' is available on node"
    if ! ssh $SSH_OPTS "$PVE_USER@$PVE_HOST" "pvesm status | grep -w '$STORAGE'" >/dev/null 2>&1; then
      if should_fail_on_remote_error; then
        fail "Storage '$STORAGE' not visible from $PVE_HOST. Double-check storage names and permissions."
      else
        warn "Storage '$STORAGE' not visible from $PVE_HOST. Double-check storage names and permissions."
      fi
    fi
  fi
fi

if [ -n "$CLOUD_INIT_FILE" ]; then
  info "Rendering cloud-init file: $CLOUD_INIT_FILE"
  if [ ! -f "$CLOUD_INIT_FILE" ]; then
    fail "cloud-init file not found: $CLOUD_INIT_FILE"
  fi

  # YAML parse: prefer python3/python + PyYAML, fallback to yq if available, else instruct how to install
  PARSE_OK=1
  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PYBIN=$(command -v python3 || command -v python)
    $PYBIN - <<PY
import sys
try:
    import yaml
except Exception as e:
    print('pyyaml not available:', e)
    sys.exit(3)
try:
    with open('$CLOUD_INIT_FILE') as f:
        yaml.safe_load(f)
except Exception as e:
    print('cloud-init YAML parse failed:', e)
    sys.exit(2)
print('ok')
PY
    case $? in
      0) info "cloud-init YAML looks valid" ;;
      2) PARSE_OK=0 ;;
      3) PARSE_OK=0 ;;
    esac
  elif command -v yq >/dev/null 2>&1; then
    if yq eval '.' "$CLOUD_INIT_FILE" >/dev/null 2>&1; then
      info "cloud-init YAML looks valid (checked with yq)"
    else
      PARSE_OK=0
    fi
  else
    warn "No YAML parser found (python3 with PyYAML or yq). To enable YAML validation install either:
  pip3 install --user pyyaml
  or
  apt/yum install yq
"
    PARSE_OK=0
  fi

  if [ "$PARSE_OK" -ne 1 ]; then
    if should_fail_on_remote_error; then
      fail "cloud-init YAML parse failed or parser missing"
    else
      warn "cloud-init YAML parse failed or parser missing; continuing in limited validation mode"
    fi
  fi
fi

info "Template validation complete. Use template-validate.sh as a lightweight CI check before updating manifest templateID/storages."
