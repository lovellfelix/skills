---
name: homelab-proxmox-cluster-api
description: Use when operating the personal homelab Kubernetes cluster on Proxmox through Cluster API and CAPMOX, especially for workload cluster rebuilds, kubeadm upgrades, templateID changes, ProxmoxMachineTemplate edits, CAPMOX boot bug recovery, management-cluster checks, cluster-status validation, or control-plane local-zfs migration planning.
metadata:
  version: 0.1.0
  portable: true
  personal_machine_only: true
  tags: [homelab, proxmox, cluster-api, capmox, kubernetes, kubeadm, ceph, infrastructure]
---

# Homelab Proxmox Cluster API

## Overview

This skill is for cluster lifecycle work on the personal homelab Kubernetes platform running on Proxmox.

Primary source of truth:
- ${GITOPS_DIR:-~/projects/gitops-homelab}/infrastructure/cluster-api/

Reference-only legacy repo:
- ${LEGACY_PROXMOX_DIR:-~/projects/proxmox/cluster-api/}

Use the GitOps repo first. Only fall back to the older repo when the newer path is missing detail, especially for template-builder workflows.

## Required env vars and onboarding snippets
Export these in your shell or CI environment as appropriate. Defaults are shown in parentheses.

- GITOPS_DIR (~/projects/gitops-homelab)
- MGMT_KUBECONFIG (~/.kube/proxmox-capi/mgmt-cluster.kubeconfig)
- WORKLOAD_KUBECONFIG (~/.kube/proxmox-homelab/workload.kubeconfig)
- PVE_HOST (pve hostname/ip)
- PVE_USER (root@pam)
- PVE_PORT (8006)
- LIVE_SECRETS (unset by default; set to 1/true when running with real Proxmox credentials to make remote validation fatal)

Example local onboarding snippet (add to your shell profile or CI environment):

export GITOPS_DIR=~/projects/gitops-homelab
export MGMT_KUBECONFIG=~/.kube/proxmox-capi/mgmt-cluster.kubeconfig
export WORKLOAD_KUBECONFIG=~/.kube/proxmox-homelab/workload.kubeconfig
# when you want full remote validation with live Proxmox credentials
# export LIVE_SECRETS=1

See docs/preflight-checklist.md for the lightweight preflight steps and dependencies (python3+pyyaml or yq for YAML parsing).

## Use when

- Rebuilding or tearing down the workload cluster.
- Building or validating a new Proxmox VM template.
- Upgrading kubeadm or kubelet versions for the homelab workload cluster.
- Checking CAPMOX, management-cluster, or ProxmoxMachine health.
- Investigating Proxmox clone failures, template issues, or CAPMOX boot bugs.
- Planning or executing control-plane storage migration from `ceph-nvme` to `local-zfs`.
- Troubleshooting `cluster not ready`, `timed out waiting for cluster Ready`, `Parameter verification failed - boot: "c;ide0"`, VM clone failures, cloud-init issues, or missing workload kubeconfig.

## Do not use when

- The task is changing a Flux-managed app or HelmRelease under `cluster/homelab/...`.
- The task is routine pod debugging inside the workload cluster.
- The target is the legacy default kubeconfig at `10.0.10.49:6443`.

## Defaults

- Management cluster kubeconfig: `~/.kube/proxmox-capi/mgmt-cluster.kubeconfig`
- Homelab workload VIP: `10.0.10.220:6443`
- Current workload manifest: `infrastructure/cluster-api/manifests/homelab-cluster.yaml`
- Current manifest versions: control plane `v1.35.0`, workers `v1.35.0`
- Current template ID in manifest: `9002`
- Current template storage in manifest: `ceph-nvme`
- Pod CIDR: `10.44.0.0/16`
- Service CIDR: `10.45.0.0/16`

## Routing

- Rebuild, build, teardown, status, preflight, kubeconfig extraction:
  - Use `gitops-homelab/infrastructure/cluster-api/scripts/`
- Template creation details and job-based builder flow:
  - Use `~/projects/proxmox/cluster-api/01-template-builder/`
- API instability tied to control-plane Ceph boot disks:
  - Read `CONTROL_PLANE_LOCAL_ZFS_MIGRATION.md` before changing templates

## Working Rules

1. Use the management kubeconfig explicitly for CAPMOX and Cluster API operations.
2. Treat `gitops-homelab/infrastructure/cluster-api/` as the durable place for manifest and script edits.
3. Prefer Git changes plus PRs for durable cluster changes.
4. Use live `kubectl patch` only for emergency remediation or validation, then backport to Git.
5. Do not flip the shared control-plane `ProxmoxMachineTemplate` from `ceph-nvme` to `local-zfs` in place.
6. If running `cluster-status.sh`, override the workload kubeconfig explicitly because the script default may lag local naming:
   - `WORKLOAD_KUBECONFIG=$HOME/.kubeconfig.homelab-cluster`

## Standard Workflow

1. Confirm the management cluster is reachable.
2. Inspect cluster status and current manifest values.
3. Decide whether the task is:
   - status/debug only
   - full rebuild
   - template creation/validation
   - kubeadm version upgrade
   - control-plane migration work
4. Make the smallest durable change in `gitops-homelab/infrastructure/cluster-api/`.
5. Validate with the repo scripts and explicit kubeconfigs.
6. If the user wants reviewable change control, create a branch, commit, and open a PR with `gh pr create`.

## Key Files

- `reference/runbook.md`
- ${GITOPS_DIR:-~/projects/gitops-homelab}/infrastructure/cluster-api/README.md
- ${GITOPS_DIR:-~/projects/gitops-homelab}/infrastructure/cluster-api/manifests/homelab-cluster.yaml
- ${GITOPS_DIR:-~/projects/gitops-homelab}/infrastructure/cluster-api/CONTROL_PLANE_LOCAL_ZFS_MIGRATION.md
- ${GITOPS_DIR:-~/projects/gitops-homelab}/infrastructure/cluster-api/FIRST_CONTROL_PLANE_REPLACEMENT_PVE22.md
- ${LEGACY_PROXMOX_DIR:-~/projects/proxmox/cluster-api/}/01-template-builder/QUICKSTART.md

## Common Mistakes

- Editing the older `~/projects/proxmox/cluster-api` repo and expecting Flux or current scripts to pick it up.
- Using the workload kubeconfig for Cluster API objects.
- Treating the `system-upgrade-controller` plans as the default homelab workload upgrade path without confirming the target cluster type.
- Changing control-plane storage in place instead of using a rolling replacement plan.
- Forgetting to validate a new template before updating manifest `templateID` or versions.

## Personal Machine Activation

- This is a personal-machine-only skill.
- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).

## Runbooks, Scripts, and CI

This skill now includes lightweight scripts and runbooks to validate templates, capture etcd snapshots, run preflight checks, and document recovery/playbooks.

Scripts (non-destructive, run locally):
- scripts/preflight.sh        - basic preflight checks (management connectivity, required tools)
- scripts/cluster-status.sh  - quick status summary for management and workload clusters
- scripts/etcd-snapshot.sh   - capture etcd snapshot from workload control-plane (if accessible)
- scripts/template-validate.sh - validate Proxmox template visibility and cloud-init YAML (safe to run in CI in limited mode)

Docs and runbooks:
- docs/preflight-checklist.md
- docs/recovery/etcd-restore.md
- docs/recovery/proxmox-template-rollback.md
- migration/control-plane-local-zfs-playbook.md

CI validation
- A GitHub Actions workflow (.github/workflows/template-validate.yml) performs lightweight template validation on pull requests.
- The workflow is intentionally non-invasive: it will run template-validate.sh in limited mode when no Proxmox secrets are provided and will only parse cloud-init YAML if present.
- To enable full remote Proxmox validation in CI, add secrets: PVE_HOST, PVE_USER, TEMPLATE_ID, and PVE_STORAGE to the repository secrets. The workflow will pick these up and run the additional checks.

Usage guidance
- Always run scripts/preflight.sh locally before performing template or control-plane changes.
- Capture an etcd snapshot and store it with the change ticket before making disruptive changes.
- Validate cloud-init locally (scripts/template-validate.sh CLOUD_INIT_FILE=...) and prefer PR-based changes to manifests.

See the individual docs in the docs/ and migration/ directories for detailed step-by-step guidance and recovery runbooks.
