---
name: homelab-gitops-flux-operations
description: Use when deploying, upgrading, reconciling, or debugging Flux-managed workloads on the personal homelab cluster, especially HelmRelease or Kustomization changes, Flux reconcile failures, app-template apps, CrashLoopBackOff or ImagePullBackOff pods, Home Assistant issues, kubectl exec troubleshooting, SOPS secret updates, or GitHub PR creation.
version: 0.1.0
portable: false
personal_machine_only: true
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

1. Durable fixes go through Git in `gitops-homelab` (one logical change per commit/PR).
2. Avoid raw `kubectl apply` against Flux-managed resources except for temporary validation, debugging, or emergency recovery; always document live patches in the PR description.
3. Prefer targeted reconciliation (see runbook one-liners) rather than full-cluster operations.
4. Inspect controller state and workload health before and after changes: `flux get hr -A`, `flux get ks -A`, `kubectl get pods -A`, and `kubectl get events -A --sort-by='.lastTimestamp'`.
5. For secrets: always edit encrypted SOPS files; never commit plaintext. Use the controlled edit and verify playbook in reference/runbook.md.
6. Use `pre-commit` on changed files before pushing. Run `pre-commit run --files <changed-files>` locally and fix lints (YAML, shellcheck, markdown, secret checks).
7. When pausing or resuming controllers or Kustomizations, prefer Flux suspend/resume commands; only suspend flux controllers when explicitly required and for a short maintenance window.
8. For urgent rollbacks prefer reverting the Git commit that introduced the change + targeted `flux reconcile` (fast, auditable). If you must use `kubectl rollout undo $KIND/$NAME` for immediate pod-level rollback, first assess stateful impacts (DB migrations, volume/schema changes) and ensure backups or a rollback plan are available.
9. Verify CRD/API compatibility before upgrading controllers or applying CRs. See the CRD validation playbook in reference/runbook.md.

## Standard Workflow (concrete playbooks)

1. Validate access and environment:

   export KUBECONFIG="$HOME/.kubeconfig.homelab-cluster"
   kubectl config current-context
   kubectl cluster-info
   kubectl get nodes

2. Locate the source files and owning Flux resource:

   # from repo root
   git grep -n "$WORKLOAD_NAME" || true
   # check Flux resources
   flux get hr -A | grep $WORKLOAD_NAME || true
   flux get ks -A | grep $AREA_OR_KUSTOMIZATION || true

3. Inspect workload & controller health (quick checklist):

   flux get hr -n <namespace>
   flux get ks -n flux-system
   kubectl -n $NAMESPACE get pods -o wide
   kubectl -n $NAMESPACE get events --sort-by='.lastTimestamp'
   kubectl -n $NAMESPACE describe pod $POD
   kubectl -n $NAMESPACE logs $POD --all-containers --tail=200

4. Make the smallest Git change (example: bump image tag in HelmRelease or add a value to kustomization):

   # edit files under cluster/homelab/$AREA/...
   git add $CHANGED_FILES
   pre-commit run --files $CHANGED_FILES || (pre-commit run --all-files && exit 1)
   git commit -m "$AREA: $WORKLOAD - $CHANGE" && git push

5. Reconcile the owning resource (one-liners in reference/runbook.md):

   # reconcile only the HelmRelease
   flux reconcile helmrelease $NAME -n $NAMESPACE --with-source

   # reconcile a Kustomization
   flux reconcile kustomization $NAME -n flux-system

6. Verify rollout and health after reconcile:

   kubectl -n $NAMESPACE rollout status deployment/$DEPLOYMENT --timeout=2m
   kubectl -n $NAMESPACE get pods -l app.kubernetes.io/name=$NAME -o wide
   flux get hr -n $NAMESPACE

7. If you performed a live patch for investigation, document it in the PR and revert the live patch or include the change in Git. Prefer this live-patch pattern when debugging:

   # live-patch container image in Deployment (temporary)
   ```bash
   kubectl -n $NAMESPACE patch deployment $DEPLOYMENT --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"myimage:debug"}]'
   ```

   # after verification: rollback or reconcile from Git
   ```bash
   kubectl -n $NAMESPACE rollout undo deployment/$DEPLOYMENT
   ```
   # or push Git change and reconcile the owning HelmRelease/Kustomization

8. When done, create PR with the validation steps and reconciliation commands you ran (copy/paste from terminal). See reference/runbook.md for quick operator one-liners for SOPS, PVC backup/restore, controller troubleshooting, Helm/Kustomize local validation, CRD checks, image pull debugging, and pre-commit guidance.

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

- `reference/runbook.md` — operator playbooks and one-liners (SOPS, reconcile/pause/resume, PVC backup/restore, controller troubleshooting, Helm/Kustomize validation, CRD checks, image pull debugging, pre-commit).
- `reference/home-assistant.md` — HA-specific notes and PVC details.
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
