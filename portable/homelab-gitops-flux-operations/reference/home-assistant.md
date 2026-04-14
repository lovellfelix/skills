# Home Assistant Notes

## Location

- App path: `cluster/homelab/default/home-assistant/ha/app/`
- Flux Kustomization: `cluster/homelab/default/home-assistant/ha/ks.yaml`
- Parent include: `cluster/homelab/default/kustomization.yaml`

## Main Resources

- HelmRelease: `home-assistant-helm-release.yaml`
- Secrets: `hass-secrets.sops.yaml`
- Connection ConfigMap: `hass-postgres-connection.yaml`
- PVC: `static.yaml`
- passwd ConfigMap: `configmap-passwd.yaml`

## Important Behavior

- Namespace: `default`
- Release name: `home-assistant`
- Ingress host: `ha.${SECRET_DOMAIN}`
- Service port: `8123`
- `hostNetwork: true`
- liveness, readiness, and startup probes are disabled
- Config volume uses existing PVC `hass-config`
- Backups mount from existing PVC `nfs-bkup-hass`
- `POSTGRES_URI` currently points to sqlite:
  - `sqlite:////config/home-assistant_v2.db`

## Good Debug Sequence

```bash
export KUBECONFIG="$HOME/.kubeconfig.homelab-cluster"
kubectl get hr home-assistant -n default
kubectl get pods -n default -l app.kubernetes.io/name=home-assistant -o wide
kubectl describe hr home-assistant -n default
kubectl describe pod <pod> -n default
kubectl logs <pod> -n default --all-containers=true --tail=200
kubectl get pvc hass-config -n default
```

If the pod is stable enough to enter:

```bash
kubectl exec -it <pod> -n default -- sh
ls -la /config
ls -la /config/backups
test -f /config/home-assistant_v2.db && echo sqlite-present
env | grep -E 'HASS|POSTGRES|TZ'
```

## Likely Failure Areas

- PVC not mounted or wrong permissions on `/config`
- sqlite file corruption or missing DB file
- secret or env substitution issues
- ingress or websocket behavior
- host-network port conflicts on `8123`
- container startup issues hidden by disabled probes

## Durable Fixes

- Edit the YAML in Git, not the live object, unless doing temporary validation.
- Reconcile with Flux after the change.
- If a secret changes, keep it encrypted with SOPS.
