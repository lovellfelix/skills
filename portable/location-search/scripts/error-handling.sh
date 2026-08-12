#!/usr/bin/env bash
# Shared error-handling helpers for opencode scripts
die() { echo "ERROR: $*" >&2; exit 1; }
log_error() { echo "ERROR: $*" >&2; }
log_warn() { echo "WARN: $*" >&2; }
log_info() { echo "INFO: $*"; }

require_command() {
  if ! command -v "$1" &>/dev/null; then
    log_error "Required command not found: $1"
    [[ -n "${2:-}" ]] && log_info "Install: $2"
    return 1
  fi
  return 0
}
