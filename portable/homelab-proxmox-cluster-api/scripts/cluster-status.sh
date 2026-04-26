#!/usr/bin/env bash
set -euo pipefail

# cluster-status.sh - summary status for management and workload clusters

MGMT_KUBECONFIG=${MGMT_KUBECONFIG:-$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig}
WORKLOAD_KUBECONFIG=${WORKLOAD_KUBECONFIG:-$HOME/.kube/proxmox-homelab/workload.kubeconfig}

info(){ echo "[info] $*"; }

if [ ! -f "$MGMT_KUBECONFIG" ]; then
  echo "Management kubeconfig not found: $MGMT_KUBECONFIG" >&2
  exit 2
fi

info "Management cluster: nodes, control-plane, and Cluster API resources"
KUBECONFIG="$MGMT_KUBECONFIG" kubectl get nodes -o wide || true
KUBECONFIG="$MGMT_KUBECONFIG" kubectl get pods -A --field-selector=status.phase!=Succeeded || true
KUBECONFIG="$MGMT_KUBECONFIG" kubectl get kubeadmcontrolplanes -A || true
KUBECONFIG="$MGMT_KUBECONFIG" kubectl get machines -A || true

if [ -f "$WORKLOAD_KUBECONFIG" ]; then
  info "Workload cluster: nodes and control-plane endpoints"
  KUBECONFIG="$WORKLOAD_KUBECONFIG" kubectl get nodes -o wide || true
  info "Control plane endpoint (from kubeconfig):"
  KUBECONFIG="$WORKLOAD_KUBECONFIG" kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' || true
else
  info "Workload kubeconfig not configured locally; skip workload checks"
fi

info "Cluster status summary complete"
