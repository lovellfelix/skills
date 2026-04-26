#!/usr/bin/env bash
set -euo pipefail

# etcd-snapshot.sh - create an etcd snapshot from the workload control-plane
# This script is non-destructive: it only triggers a snapshot using kubectl where possible

WORKLOAD_KUBECONFIG=${WORKLOAD_KUBECONFIG:-$HOME/.kube/proxmox-homelab/workload.kubeconfig}
SNAP_DIR=${SNAP_DIR:-$HOME/etcd-snapshots}
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

if [ ! -f "$WORKLOAD_KUBECONFIG" ]; then
  echo "Workload kubeconfig not found: $WORKLOAD_KUBECONFIG" >&2
  exit 2
fi

mkdir -p "$SNAP_DIR"

# 1) Try to find an etcd pod in kube-system (typical for kubeadm-managed clusters)
ETCD_POD=$(KUBECONFIG="$WORKLOAD_KUBECONFIG" kubectl get pods -n kube-system -o jsonpath="{.items[?(@.metadata.name.indexOf('etcd')>=0)].metadata.name}" 2>/dev/null || true)
ETCD_POD=${ETCD_POD%% *} # take first if multiple

if [ -n "$ETCD_POD" ]; then
  SNAP_FILE="$SNAP_DIR/etcd-snapshot-$TIMESTAMP.db"
  echo "Found etcd pod: $ETCD_POD -> copying snapshot to $SNAP_FILE"
  # This assumes the control-plane image includes etcdctl and snapshot save is possible via exec
  KUBECONFIG="$WORKLOAD_KUBECONFIG" kubectl exec -n kube-system "$ETCD_POD" -- /bin/sh -c 'ETCDCTL_API=3 etcdctl snapshot save - --endpoints=127.0.0.1:2379' > "$SNAP_FILE"
  echo "Snapshot saved to: $SNAP_FILE"
  exit 0
fi

# 2) Try to detect static or host-based etcd (static pod manifests often show up as pods with 'etcd' in the name)
ETCD_PODS_ANY=$(KUBECONFIG="$WORKLOAD_KUBECONFIG" kubectl get pods -A 2>/dev/null | grep -i etcd || true)
if [ -n "$ETCD_PODS_ANY" ]; then
  echo "Detected etcd instance(s):"
  echo "$ETCD_PODS_ANY"
  echo "If these are static or host-managed etcd instances you may need to run the snapshot command on the control-plane node(s)."
  echo "Example (run on a control-plane node):"
  echo "  sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 snapshot save /tmp/etcd-snapshot-$TIMESTAMP.db"
  echo "Then copy the resulting file off-host and move it to: $SNAP_DIR"
  exit 2
fi

# 3) No visible etcd pods found — provide explicit instructions for manual snapshot capture
cat <<EOF
No etcd pod or static etcd manifest was detected via the workload kubeconfig.
Possible reasons:
 - The workload cluster is not yet provisioned or the kubeconfig points to the wrong cluster
 - etcd runs directly on the host and is not visible as a pod from this kubeconfig

Manual snapshot options (pick one):

A) SSH to a control-plane node and run etcdctl (if etcd is available on the host):
   sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 snapshot save /tmp/etcd-snapshot-$TIMESTAMP.db
   scp user@control-plane:/tmp/etcd-snapshot-$TIMESTAMP.db $SNAP_DIR/

B) If etcd runs inside a container on the control-plane host (docker/containerd/podman):
   # find the etcd container and run etcdctl inside it, or run the host etcdctl with proper certs
   sudo docker ps | grep etcd
   sudo docker exec <container> sh -c 'ETCDCTL_API=3 etcdctl snapshot save - --endpoints=127.0.0.1:2379' > $SNAP_DIR/etcd-snapshot-$TIMESTAMP.db

C) Use kubeadm backup on a control-plane node (kubeadm provides a backup workflow for static etcd):
   sudo kubeadm alpha certs check-expiration # (example preparatory step)
   sudo kubeadm backup etcd --output /tmp/etcd-snapshot-$TIMESTAMP.db

If you cannot reach the control-plane nodes from this host, locate a machine with SSH access that can run the above commands and copy the snapshot file to this machine.

See docs/recovery/etcd-restore.md for restore instructions.
EOF

exit 3
