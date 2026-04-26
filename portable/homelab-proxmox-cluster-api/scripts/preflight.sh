#!/usr/bin/env bash
set -euo pipefail

# preflight.sh - cluster preflight checks for homelab Proxmox Cluster API workflows
# Non-destructive checks only. Exit 0 on success, non-zero on failure.

WORKLOAD_KUBECONFIG=${WORKLOAD_KUBECONFIG:-$HOME/.kube/proxmox-homelab/workload.kubeconfig}
MGMT_KUBECONFIG=${MGMT_KUBECONFIG:-$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig}
# Proxmox API host for lightweight API checks (used below)
PVE_HOST=${PVE_HOST:-localhost}
PVE_PORT=${PVE_PORT:-8006}
PVE_SCHEME=${PVE_SCHEME:-https}
# remove pveproxy binary from required commands; prefer curl-based API probe
REQUIRED_CMDS=(kubectl ssh git jq curl)

fail() { echo "ERROR: $*" >&2; exit 1; }
info(){ echo "[info] $*"; }

# check commands
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "required command not found: $cmd"
  fi
done

info "Using management kubeconfig: $MGMT_KUBECONFIG"
info "Using workload kubeconfig:  $WORKLOAD_KUBECONFIG"

if [ ! -f "$MGMT_KUBECONFIG" ]; then
  fail "management kubeconfig not found: $MGMT_KUBECONFIG"
fi

if [ ! -f "$WORKLOAD_KUBECONFIG" ]; then
  info "workload kubeconfig not found: $WORKLOAD_KUBECONFIG (this may be expected for fresh clusters)"
fi

# quick connectivity checks
info "Checking management cluster connectivity..."
if ! KUBECONFIG="$MGMT_KUBECONFIG" kubectl get pods -A --request-timeout=10s >/dev/null 2>&1; then
  fail "cannot reach management cluster with $MGMT_KUBECONFIG"
fi

info "Checking Cluster API objects (Machines, KubeadmControlPlane)..."
KUBECONFIG="$MGMT_KUBECONFIG" kubectl get machinedeployments,machines,kubeadmcontrolplanes --all-namespaces || true

info "Validating Proxmox API reachability ($PVE_HOST:$PVE_PORT)..."
# Lightweight API probe: /api2/json/version responds on a healthy Proxmox API endpoint
if ! curl --max-time 5 --silent --insecure -f "${PVE_SCHEME}://${PVE_HOST}:${PVE_PORT}/api2/json/version" >/dev/null 2>&1; then
  info "Proxmox API did not respond to HTTP probe. Ensure the API is reachable from this host and PVE_HOST:PVE_PORT are correct"
fi

info "Preflight checks complete. Review output for warnings."
exit 0
