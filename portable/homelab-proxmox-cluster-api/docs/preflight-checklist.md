# Preflight Checklist

This checklist is a lightweight set of non-destructive checks to run before performing cluster changes (template updates, control-plane replacements, kubeadm upgrades, or templateID changes).

- Required environment variables / local defaults
  - MGMT_KUBECONFIG (default: ~/.kube/proxmox-capi/mgmt-cluster.kubeconfig)
  - WORKLOAD_KUBECONFIG (default: ~/.kube/proxmox-homelab/workload.kubeconfig)
  - GITOPS_DIR (default: ~/projects/gitops-homelab)
  - PVE_HOST / PVE_USER / PVE_PORT (when running Proxmox checks)
  - LIVE_SECRETS (set to 1/true when running with real Proxmox credentials to make remote validation fatal)

- Confirm management kubeconfig is present and reachable
  - Default: $MGMT_KUBECONFIG
  - Run: KUBECONFIG="$MGMT_KUBECONFIG" kubectl get pods -A

- Run scripts/preflight.sh from your workstation
  - Ensures required tools exist and that the management cluster is reachable and that the Proxmox API is reachable (lightweight HTTP probe)

- Capture an etcd snapshot (if workload cluster exists)
  - scripts/etcd-snapshot.sh -> saves snapshot to $HOME/etcd-snapshots (or prints manual instructions if snapshot cannot be captured automatically)
  - If the script cannot capture a snapshot automatically it will print explicit instructions for running etcdctl/kubeadm backup on a control-plane node. Store snapshot off-host or attach to ticket.

- Validate any cloud-init userdata you will ship with the template
  - scripts/template-validate.sh CLOUD_INIT_FILE=path/to/user-data
  - YAML parsing requires either python3 + PyYAML (pip3 install --user pyyaml) or yq. The script will attempt to use python3/python then yq and otherwise print installation instructions.

- Validate the Proxmox template and storage visibility
  - scripts/template-validate.sh TEMPLATE_ID=9002 PVE_HOST=pve.local PVE_USER=root@pam STORAGE=ceph-nvme
  - When LIVE_SECRETS is not set, remote Proxmox/SSH failures are treated as warnings so the script is safe to run in CI without secrets. Set LIVE_SECRETS=1 to make failures fatal for full validation runs.

- Create a branch, commit the manifest change, and open a PR
  - Add the template validation CI status to the PR where possible

- For control-plane storage migration or template swaps do a staged replacement (see migration/control-plane-local-zfs-playbook.md)

- For emergency rollback plan ahead:
  - Have an etcd snapshot ready
  - Know how to rollback a Proxmox VM from its snapshot or revert to the previous templateID
  - Follow docs/recovery/etcd-restore.md and docs/recovery/proxmox-template-rollback.md

Keep this checklist small and repeatable; run it every time you update templateID or storage in manifests.
