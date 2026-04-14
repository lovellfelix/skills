---
name: homelab-proxmox-cluster-api
description: Use when operating the personal homelab Kubernetes cluster on Proxmox through Cluster API and CAPMOX, especially for workload cluster rebuilds, kubeadm upgrades, templateID changes, ProxmoxMachineTemplate edits, CAPMOX boot bug recovery, management-cluster checks, cluster-status validation, or control-plane local-zfs migration planning.
version: 0.1.0
portable: true
tags: [homelab, proxmox, cluster-api, capmox, kubernetes, kubeadm, ceph, infrastructure]
---

# Homelab Proxmox Cluster API

## Overview

This skill is for cluster lifecycle work on the personal homelab Kubernetes platform running on Proxmox.

Primary source of truth:
- `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/`

Reference-only legacy repo:
- `/Users/lovellfelix/projects/proxmox/cluster-api/`

Use the GitOps repo first. Only fall back to the older repo when the newer path is missing detail, especially for template-builder workflows.

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
- `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/README.md`
- `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/manifests/homelab-cluster.yaml`
- `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/CONTROL_PLANE_LOCAL_ZFS_MIGRATION.md`
- `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/FIRST_CONTROL_PLANE_REPLACEMENT_PVE22.md`
- `/Users/lovellfelix/projects/proxmox/cluster-api/01-template-builder/QUICKSTART.md`

## Common Mistakes

- Editing the older `~/projects/proxmox/cluster-api` repo and expecting Flux or current scripts to pick it up.
- Using the workload kubeconfig for Cluster API objects.
- Treating the `system-upgrade-controller` plans as the default homelab workload upgrade path without confirming the target cluster type.
- Changing control-plane storage in place instead of using a rolling replacement plan.
- Forgetting to validate a new template before updating manifest `templateID` or versions.

## Personal Machine Activation

- This is a personal-machine-only skill and stays disabled unless explicitly allowlisted.
- Add `homelab-proxmox-cluster-api` to `~/.personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist.
