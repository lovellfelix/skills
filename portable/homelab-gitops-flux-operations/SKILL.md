---
name: homelab-gitops-flux-operations
description: Use when deploying, upgrading, reconciling, or debugging Flux-managed workloads on the personal homelab cluster, especially HelmRelease or Kustomization changes, Flux reconcile failures, app-template apps, CrashLoopBackOff or ImagePullBackOff pods, Home Assistant issues, kubectl exec troubleshooting, SOPS secret updates, or GitHub PR creation.
version: 0.1.0
portable: true
tags: [homelab, flux, gitops, kubernetes, helmrelease, home-assistant, sops, troubleshooting]
---

# Homelab GitOps Flux Operations

## Overview

This skill is for workload operations inside the homelab cluster managed from:

- `/Users/lovellfelix/projects/gitops-homelab`

It covers Flux, HelmRelease edits, Kustomizations, app-template usage, Home Assistant debugging, pod exec sessions, and PR-based delivery.

## Use when

- Adding or updating a HelmRelease under `cluster/homelab/...`.
- Deploying a new app through Flux.
- Debugging pods, events, container logs, PVCs, services, or ingress.
- Troubleshooting Home Assistant.
- Reconciling broken Flux Kustomizations or HelmReleases.
- Creating a Git branch, commit, and PR for workload changes.
- Handling `CrashLoopBackOff`, `ImagePullBackOff`, failed Flux health checks, substitution errors, SOPS decryption problems, ingress misroutes, PVC mount issues, or container startup failures.

## Do not use when

- The task is Cluster API, CAPMOX, Proxmox template, or management-cluster lifecycle work.
- The user is targeting the legacy cluster at `10.0.10.49:6443`.
- The change is meant to be a one-off live patch with no durable Git change.

## Cluster Access Rules

- Always use: `export KUBECONFIG=$HOME/.kubeconfig.homelab-cluster`
- Required context: `homelab-admin@homelab`
- If errors mention `10.0.10.49:6443`, the command hit the legacy cluster and must be corrected.

Validate before cluster work:

```bash
export KUBECONFIG=$HOME/.kubeconfig.homelab-cluster
kubectl config current-context
kubectl cluster-info
kubectl get nodes
```

## Repo Layout

- Root Kustomizations: `cluster/homelab/<area>/ks.yaml`
- Namespace trees: `cluster/homelab/default/`, `media/`, `networking/`, `kube-system/`, `remote/`, `storage/`, `database/`, `monitoring/`
- New apps usually need:
  - an app directory
  - a `HelmRelease` or nested `ks.yaml`
  - parent `kustomization.yaml` update if the area uses one
  - Flux reconciliation or PR

## Chart Conventions

- Prefer app-template `4.x` for new apps.
- Preserve the current chart major version for existing apps unless the task is an intentional migration.
- Use existing examples before inventing new structure:
  - app-template 4.x example: `cluster/homelab/default/atuin/atuin-helm-release.yaml`
  - app-template 4.x multi-replica example: `cluster/homelab/remote/openssh/helm-release-openssh.yaml`
  - Home Assistant legacy app-template 2.x example: `cluster/homelab/default/home-assistant/ha/app/home-assistant-helm-release.yaml`

## Working Rules

1. Durable fixes go through Git in `gitops-homelab`.
2. Avoid raw `kubectl apply` against Flux-managed resources except for temporary validation or emergency recovery.
3. Reconcile with Flux after Git changes or when verifying controller state.
4. Check `flux get hr -A` and `flux get ks -A` before and after changes.
5. For secrets, preserve SOPS and do not commit decrypted material.
6. Use `pre-commit` on changed files before finishing if you edited YAML or Markdown.

## Standard Workflow

1. Verify homelab kubeconfig and context.
2. Identify the workload path and owning Flux Kustomization.
3. Inspect current health with Flux, pods, events, and logs.
4. Apply the smallest Git change.
5. Validate locally.
6. Reconcile the specific HelmRelease or Kustomization if the task includes live verification.
7. If requested, commit and create a PR with `gh pr create`.

## Home Assistant Defaults

- Path: `cluster/homelab/default/home-assistant/ha/`
- Flux Kustomization: `home-assistant`
- HelmRelease: `home-assistant`
- Namespace: `default`
- Host: `ha.${SECRET_DOMAIN}`
- Main PVC: `hass-config`
- Backup PVC: `nfs-bkup-hass`
- Uses `hostNetwork: true`
- Probes are disabled
- `hass-postgres-connection` currently sets `POSTGRES_URI: sqlite:////config/home-assistant_v2.db`

That means Home Assistant troubleshooting should check the mounted config volume and sqlite path first, not assume live Postgres usage.

## Key Files

- `reference/runbook.md`
- `reference/home-assistant.md`
- `/Users/lovellfelix/projects/gitops-homelab/AGENTS.md`
- `/Users/lovellfelix/projects/gitops-homelab/docs/app-template-guide.md`

## Common Mistakes

- Using the default kubeconfig instead of `~/.kubeconfig.homelab-cluster`.
- Editing app YAML without updating the owning parent `kustomization.yaml` or `ks.yaml`.
- Assuming every app uses app-template 4.x.
- Debugging Home Assistant like a stateless web app when it is volume-backed and running with `hostNetwork` and no probes.
- Forgetting to reconcile Flux or inspect controller errors after a Git change.

## Personal Machine Activation

- This is a personal-machine-only skill and stays disabled unless explicitly allowlisted.
- Add `homelab-gitops-flux-operations` to `~/.personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist.
