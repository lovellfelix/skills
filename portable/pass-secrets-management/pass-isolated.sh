#!/usr/bin/env bash
# pass-isolated.sh — One-off isolated secret storage for agent workflows
# Usage: source this file, then use the functions
#
# Example:
#   source pass-isolated.sh
#   isolated_init
#   isolated_store "temp/api-key" "$MY_SECRET"
#   isolated_retrieve "temp/api-key"
#   isolated_cleanup

set -euo pipefail

# Store the original password store directory
_PASS_ORIG_STORE="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
_PASS_ISOLATED_DIR=""
_PASS_ISOLATED_ACTIVE=false

# Anti-leak: disable command substitution logging
disable_secret_logging() {
    # Disable trace for sensitive operations
    if [[ $- == *x* ]]; then
        _PASS_TRACE_WAS_ON=true
        set +x
    else
        _PASS_TRACE_WAS_ON=false
    fi
}

restore_secret_logging() {
    if [[ "${_PASS_TRACE_WAS_ON:-false}" == true ]]; then
        set -x
    fi
}

# Anti-leak: sanitize function - ensures no secret value is echoed
_pass_sanitize_output() {
    local line
    while IFS= read -r line; do
        # Only print path/status, never secret values
        echo "[SECRET RETRIEVED]" >&2
    done
}

isolated_init() {
    # Create a temporary isolated pass store
    _PASS_ISOLATED_DIR=$(mktemp -d)
    export PASSWORD_STORE_DIR="$_PASS_ISOLATED_DIR"
    
    # Get the default GPG key
    local gpg_key
    gpg_key=$(gpg --list-keys --keyid-format long 2>/dev/null | grep -E '^pub' | head -1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [[ -z "$gpg_key" ]]; then
        echo "ERROR: No GPG key found. Initialize gpg first." >&2
        return 1
    fi
    
    # Disable trace logging during pass operations
    disable_secret_logging
    
    pass init "$gpg_key" 2>/dev/null
    _PASS_ISOLATED_ACTIVE=true
    
    restore_secret_logging
    
    echo "Isolated pass store initialized: $_PASS_ISOLATED_DIR"
    echo "All operations are scoped to this temporary store."
    echo "Store is gitignored and will be deleted on cleanup."
}

isolated_store() {
    local path="$1"
    local value="$2"
    
    if [[ "$_PASS_ISOLATED_ACTIVE" != true ]]; then
        echo "ERROR: Call isolated_init first" >&2
        return 1
    fi
    
    disable_secret_logging
    
    echo "$value" | pass insert --force "$path"
    
    restore_secret_logging
    
    # Log path only, never the value
    echo "Stored: $path (isolated)"
}

isolated_retrieve() {
    local path="$1"
    
    if [[ "$_PASS_ISOLATED_ACTIVE" != true ]]; then
        echo "ERROR: Call isolated_init first" >&2
        return 1
    fi
    
    disable_secret_logging
    
    # Output goes to stdout for variable capture
    # Never log or echo the value
    pass show "$path" | head -1
    
    restore_secret_logging
}

isolated_generate() {
    local path="$1"
    local length="${2:-32}"
    local symbols="${3:-}"
    
    if [[ "$_PASS_ISOLATED_ACTIVE" != true ]]; then
        echo "ERROR: Call isolated_init first" >&2
        return 1
    fi
    
    disable_secret_logging
    
    if [[ "$symbols" == "--no-symbols" ]]; then
        pass generate -n "$path" "$length"
    else
        pass generate "$path" "$length"
    fi
    
    # Output goes to stdout for variable capture
    pass show "$path" | head -1
    
    restore_secret_logging
}

isolated_list() {
    local path="${1:-}"
    
    if [[ "$_PASS_ISOLATED_ACTIVE" != true ]]; then
        echo "ERROR: Call isolated_init first" >&2
        return 1
    fi
    
    # Listing paths is safe - no secret values exposed
    if [[ -n "$path" ]]; then
        pass ls "$path"
    else
        pass ls
    fi
}

isolated_cleanup() {
    if [[ -n "$_PASS_ISOLATED_DIR" && -d "$_PASS_ISOLATED_DIR" ]]; then
        disable_secret_logging
        
        # Securely delete: overwrite before rm
        find "$_PASS_ISOLATED_DIR" -type f -exec sh -c 'dd if=/dev/urandom of="$1" bs=1 count=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null) conv=notrunc 2>/dev/null; rm -f "$1"' _ {} \; 2>/dev/null || true
        
        rm -rf "$_PASS_ISOLATED_DIR"
        
        restore_secret_logging
        
        echo "Isolated store securely cleaned up."
    fi
    
    export PASSWORD_STORE_DIR="$_PASS_ORIG_STORE"
    _PASS_ISOLATED_DIR=""
    _PASS_ISOLATED_ACTIVE=false
}

# Permission check helper
check_permission() {
    local path="$1"
    local agent_name="${2:-unknown}"
    local reason="${3:-}"
    
    # Check if path is in personal namespace
    if [[ "$path" == personal/* ]]; then
        echo "PERMISSION REQUIRED" >&2
        echo "Agent: $agent_name" >&2
        echo "Path: $path" >&2
        echo "Reason: $reason" >&2
        echo "Access to personal/ namespace requires user approval." >&2
        return 1
    fi
    
    # Check if path is in another agent's namespace
    if [[ "$path" == agents/* ]]; then
        local target_agent
        # Extract second path component: agents/<agent-name>/...
        target_agent="${path#agents/}"
        target_agent="${target_agent%%/*}"
        if [[ "$target_agent" != "$agent_name" ]]; then
            echo "PERMISSION REQUIRED" >&2
            echo "Agent: $agent_name" >&2
            echo "Path: $path" >&2
            echo "Target agent: $target_agent" >&2
            echo "Reason: $reason" >&2
            echo "Access to another agent's namespace requires user approval." >&2
            return 1
        fi
    fi
    
    return 0
}

# If run directly (not sourced), show usage
if [[ -n "${BASH_SOURCE[0]+x}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Usage: source this file, then use the functions:"
    echo ""
    echo "  isolated_init              # Create temporary store"
    echo "  isolated_store path value  # Store a secret"
    echo "  isolated_retrieve path     # Get a secret (first line)"
    echo "  isolated_generate path [len] [--no-symbols]  # Generate random"
    echo "  isolated_list [path]       # List stored secrets (paths only)"
    echo "  isolated_cleanup           # Securely remove temporary store"
    echo "  check_permission path agent reason  # Check access authorization"
    echo ""
    echo "Example:"
    echo "  source pass-isolated.sh"
    echo "  isolated_init"
    echo "  isolated_store 'temp/debug-key' 'abc123'"
    echo "  isolated_retrieve 'temp/debug-key'"
    echo "  isolated_cleanup"
fi
