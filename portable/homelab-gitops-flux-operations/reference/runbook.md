# Homelab GitOps Runbook

## First Checks

```bash
export KUBECONFIG="$HOME/.kubeconfig.homelab-cluster"
kubectl config current-context
kubectl cluster-info
kubectl get nodes
flux get ks -A
flux get hr -A
```

If `kubectl cluster-info` or error output references `10.0.10.49:6443`, stop and switch kubeconfig.

## New App Workflow

1. Pick the target area under `cluster/homelab/`.
2. Decide whether the app should use:
   - app-template 4.x
   - an upstream chart
   - a nested Flux Kustomization
3. Copy a nearby working example instead of starting from scratch.
4. Add any required `ks.yaml`, `kustomization.yaml`, secrets, PVCs, or ConfigMaps.
5. Update the parent `kustomization.yaml` if that area uses one.
6. Run validation on changed files.
7. Reconcile the owning Kustomization or HelmRelease.

Useful examples:

- app-template 4.x default namespace app: `cluster/homelab/default/atuin/`
- app-template 4.x remote namespace app: `cluster/homelab/remote/openssh/`
- custom upstream chart: `cluster/homelab/default/reverse-proxy/`

## Reconcile Commands

Specific HelmRelease:

```bash
flux reconcile helmrelease <name> -n <namespace> --with-source
```

Specific Kustomization:

```bash
flux reconcile kustomization <name> -n flux-system
```

Git source refresh:

```bash
flux reconcile source git flux-system -n flux-system
```

## Pod Troubleshooting Workflow

1. Find the workload:

```bash
kubectl get pods -n <namespace> -o wide
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

2. Inspect the owning objects:

```bash
kubectl describe pod <pod> -n <namespace>
kubectl describe deploy <deploy> -n <namespace>
kubectl describe helmrelease <name> -n <namespace>
```

3. Check logs:

```bash
kubectl logs <pod> -n <namespace> --all-containers=true --tail=200
kubectl logs <pod> -n <namespace> -c <container> --previous --tail=200
```

4. Exec only after you know the right container and pod are healthy enough to enter:

```bash
kubectl exec -it <pod> -n <namespace> -c <container> -- sh
```

5. If PVC, service, or ingress is involved, inspect those too:

```bash
kubectl get pvc,svc,ing -n <namespace>
kubectl describe pvc <name> -n <namespace>
```

## Validation Before Finish

From repo root `/Users/lovellfelix/projects/gitops-homelab`:

```bash
pre-commit run --files <changed-files>
```

The repo has hooks for:

- YAML lint
- Markdown lint
- shellcheck
- secret checks

## PR Workflow

1. Create a branch in `gitops-homelab`.
2. Stage only the intended workload files.
3. Commit with a focused message.
4. Push and create a PR with `gh pr create`.
5. Mention:
   - workload name
   - namespace
   - chart/version or image/tag change
   - validation and reconciliation steps run

Note: `.github/workflows/diff-hr-on-pr.yaml` comments rendered diffs for HelmRelease changes that include the `registryUrl=` renovate comment pattern.
