# Homelab GitOps Runbook

## Prerequisites

Required CLIs and quick verification tips (run these before making changes):

- kubectl (v1.26+ recommended)
  - verify: kubectl version --client && kubectl config current-context
- flux (flux cli)
  - verify: flux --version && flux get ks -A || true
- git and gh (GitHub CLI) for PR workflow
  - verify: git --version && gh --version
- sops (Mozilla SOPS) for secrets management
  - verify: sops --version && sops -v $(git ls-files | grep -m1 '\.sops\.yaml' || true) || true
- yq / jq for safe YAML/JSON inspection
  - verify: yq --version || jq --version || true
- docker / skopeo (for registry checks)
  - verify: docker --version || skopeo --version || true
- age / gpg / cloud KMS CLIs as used by your SOPS config (age/pgp/gcp-kms/aws-kms)
  - verify: age --version || gpg --list-keys || gcloud --version || aws --version

Tip: Install CLIs via your platform package manager (brew/apt) and ensure they are on PATH. When in doubt, run the verify commands above and fix auth (aws configure, gcloud auth login, docker login) before proceeding.


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
flux reconcile helmrelease $NAME -n $NAMESPACE --with-source
```

Specific Kustomization:

```bash
flux reconcile kustomization $NAME -n flux-system
```

Git source refresh:

```bash
flux reconcile source git flux-system -n flux-system
```

## Pod Troubleshooting Workflow

1. Find the workload:

```bash
kubectl get pods -n $NAMESPACE -o wide
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
```

2. Inspect the owning objects:

```bash
kubectl describe pod $POD -n $NAMESPACE
kubectl describe deploy $DEPLOYMENT -n $NAMESPACE
kubectl describe helmrelease $NAME -n $NAMESPACE
```

3. Check logs:

```bash
kubectl logs $POD -n $NAMESPACE --all-containers=true --tail=200
kubectl logs $POD -n $NAMESPACE -c $CONTAINER --previous --tail=200
```

4. Exec only after you know the right container and pod are healthy enough to enter:

```bash
kubectl exec -it $POD -n $NAMESPACE -c $CONTAINER -- sh
```

5. If PVC, service, or ingress is involved, inspect those too:

```bash
kubectl get pvc,svc,ing -n $NAMESPACE
kubectl describe pvc $NAME -n $NAMESPACE
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


## Operator Playbooks (one-liners and quick procedures)

This section collects short, copy-paste playbooks for common operator tasks. When in doubt: document everything you ran and prefer the Git-based durable fix.

### SOPS - safe edit, verification, and rotation (hardened)

# Interactive safe edit (opens $EDITOR, re-encrypts on save)
SOPS_FILE=cluster/homelab/.../secret.sops.yaml
sops "$SOPS_FILE"

# Verify decrypted contents without writing plaintext to disk
# (streams plaintext to stdout — do not redirect to a file)
sops -d "$SOPS_FILE" | yq -P . | head -n 200

# Show SOPS metadata (who can decrypt, KMS/AGE recipients)
sops -v "$SOPS_FILE" || true

Checklist - SOPS safe handling (pre-merge or emergency)
- Never commit plaintext or decrypted output. Always use `sops <file>` to edit.
- Avoid editors that write swap/backup files into the repo working tree. If you must, use an ephemeral tmpfs or an isolated worktree:
  - mkdir -p /dev/shm/sops-edit && export EDITOR="vim -R" && SOPS_TMP=/dev/shm/sops-edit sops "$SOPS_FILE"
- When piping decrypted output, never redirect to a tracked file. Use pipes to tools that can read stdin (yq, jq) or an encrypted temp file on tmpfs.
- Verify there are no on-disk traces: grep for recent plaintext patterns and remove any temporary swap files (vim swap, emacs, .bak) before committing.
- For accidental plaintext exposure:
  1) Treat as an incident: capture who had access and when.
  2) Rotate any credentials found in the plaintext immediately (see rotation steps below).
  3) Remove the plaintext from VCS history if it was committed (use `git revert` or `git filter-repo` with caution and team coordination).

Key rotation & recipient management (prescriptive)
- Add new keys or recipients to your keyrings / KMS (AGE, GCP KMS, AWS KMS, etc.).

Atomic, file-safe rotation example (recommended)
- Work in a local branch and prepare a small script that decrypts -> re-encrypts to a temp file, then atomically moves the new ciphertext into place. This avoids leaving partially written files if the operation is interrupted:

```bash
# run from repo root on a branch like rotate/sops/<date>
for f in $(git ls-files "*.sops.yaml"); do
  umask 077  # ensure the temp file is created with restrictive permissions
  tmp=$(mktemp)
  # decrypt to a secure temp file
  sops -d "$f" > "$tmp" || { rm -f "$tmp"; echo "decrypt failed: $f"; exit 1; }
  # re-encrypt the plaintext temp into a new ciphertext file
  sops -e "$tmp" > "$f".tmp || { rm -f "$tmp" "$f".tmp; echo "re-encrypt failed: $f"; exit 1; }
  # atomically replace the original file
  mv "$f".tmp "$f"
  # securely remove the plaintext temp
  rm -f "$tmp"
done
# review changes, commit and open a PR
git add -A && git commit -m "rotate(sops): update recipients" && git push --set-upstream origin HEAD
```

- Commit with a clear message: "rotate(sops): add/remove recipients"
- Verify decryption works locally for intended recipients: sops -d <file> | yq -P .  (do NOT redirect to a tracked file)
- Push and create a PR for audit. Do not bulk-push to main without peer review.

Checklist: verify KMS/AGE environment before rotating
- For AWS KMS: ensure CLI credentials are valid: aws sts get-caller-identity
- For GCP KMS: ensure application default credentials: gcloud auth application-default login && gcloud auth list
- For AGE: confirm AGE_KEY or recipient key files are available and permissions are correct; test with: age --version and attempt a local encrypt/decrypt using the recipient keys.
- Test a single file decryption/encryption round-trip before doing all files: sops -d file.sops.yaml | yq -P . && sops -e <(sops -d file.sops.yaml) > file.sops.yaml.tmp && rm file.sops.yaml.tmp
- Confirm sops shows the expected recipients and metadata: sops -v <file> || true
- Ensure CI runners that need to decrypt have minimal access and do not log secrets. Schedule secrets rotation in coordination with services that depend on them.


Verification & safety operators
- Confirm no swap/backup files in repo: git status --porcelain | grep -E "\.(swp|swo|bak|~)$" || true
- Ensure CI decrypts only in ephemeral runners with limited logs; never print secrets in CI logs.


### Reconcile / Pause / Resume / Live-patch / Rollback (prescriptive, safe ordering)

Purpose: change or pause reconciliation safely with minimal drift and clear recovery.

Prescriptive checklist (suspend/resume/revert)
1) Identify owning controllers and dependent kustomizations/helmreleases.
   - flux get hr -A | grep <workload>
   - flux get ks -A | grep <area>

2) Suspend child workloads first, then parent kustomizations/controllers as required.
   - Example safe order to pause for disruptive Git revert or controller upgrade:
     a) flux suspend helmrelease <child-hr> -n <ns>  # pause app-level HRs
     b) flux suspend kustomization <parent-kustomization> -n flux-system  # then pause parent

3) Wait for in-flight reconciliations to stop (recommended wait 30s-2m depending on cluster load). Verify:
   - kubectl -n <namespace> get pods --selector=app.kubernetes.io/name=<app> -o wide
   - flux get hr -n <namespace>

4) Perform the change (git revert / image rollback / live patch / controller upgrade).
   - For fast rollback prefer: kubectl -n <namespace> rollout undo deployment/<deployment>
   - For durable rollback prefer: git revert <commit-sha> && git push && flux reconcile source git flux-system -n flux-system && flux reconcile kustomization <kustomization-name> -n flux-system

5) Reconcile sources & controllers in safe order and wait for healthy status:
   - flux reconcile source git flux-system -n flux-system
   - flux reconcile kustomization <kustomization-name> -n flux-system
   - Wait and verify: flux get ks -n flux-system; kubectl -n <namespace> rollout status deployment/<deployment> --timeout=3m

6) Resume in reverse order (parent last):
   - flux resume kustomization <parent-kustomization> -n flux-system
   - flux resume helmrelease <child-hr> -n <ns>

7) Post-verify: check pods, events, controller logs and Flux health. Document the steps in PR/incident ticket.

Live-patch guidance (temporary only)
- Apply the patch with a clear marker in the commit message or PR body that it is temporary and must be reverted or included in Git.
- Undo immediately if investigation is complete: kubectl -n <namespace> rollout undo deployment/<deployment>

# Fast, auditable rollback (preferred): revert the Git commit and reconcile the owning Kustomization/HelmRelease

# Safety first
- Before reverting, assess whether the change involved stateful data (database migrations, volume formats) or dependent services. If so, coordinate with service owners and take backups (PVC/db dump) before reverting.
- Prefer a PR-based revert that documents the reason and allows CI checks to run prior to merging.

# Steps (example)
- git revert <commit-sha>
- git push origin HEAD && gh pr create --fill --title "revert: <commit-sha> - <reason>"
- After PR merges: flux reconcile source git flux-system -n flux-system && flux reconcile kustomization <kustomization-name> -n flux-system
- Verify: kubectl -n <namespace> rollout status deployment/<deployment> --timeout=3m; check events and controller logs

# Suspend (pause) a Kustomization or HelmRelease (one-liners)
flux suspend helmrelease <name> -n <namespace>
flux suspend kustomization <name> -n flux-system

# Resume (one-liners)
flux resume kustomization <name> -n flux-system
flux resume helmrelease <name> -n <namespace>

# Live patch example (temporary)
kubectl -n <namespace> patch deployment <deployment> --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"myimage:debug"}]'

# Revert a live patch (immediate)
kubectl -n <namespace> rollout undo deployment/<deployment>


### Controller troubleshooting (flux controllers)

One-liner: restart controllers safely and collect diagnostics
kubectl -n flux-system rollout restart deployment/<controller-deployment> && kubectl -n flux-system rollout status deployment/<controller-deployment> --timeout=2m

Quick checklist for controller CrashLoop/upgrade issues
1) Collect diagnostics (pre-restart):
   - kubectl -n flux-system get pods -o wide
   - kubectl -n flux-system get events --sort-by='.lastTimestamp'
   - kubectl -n flux-system logs deployment/<controller-deployment> -c manager --tail=500 || true
   - kubectl -n flux-system describe deployment <controller-deployment>
   - kubectl -n flux-system get replicaset -o wide

2) Safe restart (preferred over killing pods):
   - kubectl -n flux-system rollout restart deployment/<controller-deployment>
   - Wait for healthy rollout: kubectl -n flux-system rollout status deployment/<controller-deployment> --timeout=2m

3) If rollout fails or controllers continue to CrashLoop:
   - kubectl -n flux-system rollout undo deployment/<controller-deployment>
   - Re-check logs: kubectl -n flux-system logs deployment/<controller-deployment> -c manager --tail=500
   - Reconcile sources: flux reconcile source git flux-system -n flux-system
   - Inspect cluster resources referenced by controllers (CRDs, Secrets, ServiceAccounts, RBAC)

4) Escalation point (when to stop and call for help):
   - If controller continues to restart >3 times within 10 minutes or pods are OOMKilled repeatedly, collect the following and escalate to cluster admin/owner:
     - kubectl -n flux-system get pods -o wide > flux-pods.txt
     - kubectl -n flux-system logs deployment/<controller-deployment> -c manager --tail=200 > flux-controller.log
     - kubectl -n flux-system get events --sort-by='.lastTimestamp' > flux-events.txt
     - kubectl get crd -o wide > crd-list.txt
   - Open an incident/PR with these artifacts and include recent Git commits that correspond to the failing reconciliation.

Diagnostic commands (helpful checks)
- Check CRD presence and versions that controllers expect:
  kubectl get crd | grep -E "(helm|kustomization|sources|helmreleases)" || true
- Check API discovery for a specific kind:
  kubectl api-resources | grep -i <kind>

Notes:
- Avoid manually deleting controller pods repeatedly; use rollout restart/undo for safer state transitions.
- When upgrading a controller, perform CRD & CR backups first (see CRD backup section below).


### PVC backup & restore (safe, application-aware)

High level: quiesce the app, take an application-aware dump when possible (database dumps), or filesystem archive for file-backed apps. Store copies off-cluster with retention and verification.

Prescriptive checklist for PVC backup
1) Identify the app and data type (files vs databases). Locate PVC and owning workload.
   - kubectl -n <ns> get pvc
   - kubectl -n $NS get deploy,statefulset -o wide | grep $APP

2) Quiesce the app safely:
   - Scale down or put into maintenance mode (prefer app-level maintenance endpoint when available):
     kubectl -n <ns> scale --replicas=0 deployment/<deployment>
     or for statefulsets: kubectl -n <ns> scale --replicas=0 statefulset/$STS
   - Wait for pods to terminate: kubectl -n <ns> get pods --selector=app.kubernetes.io/name=<app>

3) Application-aware dump (preferred for DBs):
   - Postgres example (run from helper pod or inside DB pod):
     kubectl -n $NS exec -it $PG_POD -- pg_dumpall -U $DB_USER > /tmp/pg-backup.sql
     kubectl -n $NS cp $PG_POD:/tmp/pg-backup.sql ./pg-backup-$(date +%Y%m%d%H%M).sql
   - MySQL example:
     ```bash
# Prompt for the MySQL password to avoid embedding credentials in scripts or history
read -rsp "MySQL password for $MYSQL_USER: " MYSQL_PASS
kubectl -n $NS exec $MYSQL_POD -- mysqldump --all-databases -u"$MYSQL_USER" -p"$MYSQL_PASS" > /tmp/mysql-backup.sql
kubectl -n $NS cp $MYSQL_POD:/tmp/mysql-backup.sql ./mysql-backup-$(date +%Y%m%d%H%M).sql
```


4) Filesystem archive (when app-aware dump not available):
   - Create helper pod that mounts the PVC and archives the data (example below)

# Helper pod (archive to /tmp inside pod)
cat <<'EOF' | kubectl -n $NAMESPACE apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pvc-backup
spec:
  containers:
  - name: backup
    image: alpine:3.18
    command: ["sleep","3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: <pvc-name>
  restartPolicy: Never
EOF

kubectl -n $NAMESPACE exec pvc-backup -- tar czf /tmp/backup.tgz -C /data .
kubectl -n $NAMESPACE cp pvc-backup:/tmp/backup.tgz ./$PVC_NAME-backup-$(date +%Y%m%d%H%M).tgz
kubectl -n $NAMESPACE delete pod pvc-backup

5) Restore: reverse the steps and prefer app-aware restore when available
- Application restore (Postgres example): kubectl -n <ns> cp ./pg-backup.sql <pg-pod>:/tmp/pg-backup.sql && kubectl -n <ns> exec -it <pg-pod> -- psql -U <user> -f /tmp/pg-backup.sql
- Filesystem restore using helper pod example below (copy archive into pod and extract)

# Restore helper pod
kubectl -n $NAMESPACE apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pvc-restore
spec:
  containers:
  - name: restore
    image: alpine:3.18
    command: ["sleep","3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: <pvc-name>
  restartPolicy: Never
EOF

kubectl -n $NAMESPACE cp ./$PVC_NAME-backup-*.tgz pvc-restore:/tmp/backup.tgz
kubectl -n $NAMESPACE exec pvc-restore -- sh -c 'cd /data && tar xzf /tmp/backup.tgz'
kubectl -n $NAMESPACE delete pod pvc-restore

6) Post-restore verification
- Start the app (scale to previous replicas) and run health checks
- For DBs: validate schema and a sample query
- For file-backed apps: check key files and timestamps

7) Offsite retention & naming policy (example)
- Keep 7 daily backups, 4 weekly, 6 monthly. Store off-cluster in S3/NFS with immutable names.
- Naming: $CLUSTER-$NS-$PVC-YYYYMMDDHHMM.tgz or .sql
- Verify integrity after copy: sha256sum and store checksum alongside the artifact

Notes:
- Always prefer application-aware dumps for databases (pg_dump, mysqldump, mongodump) rather than raw filesystem copy where possible.
- Where consistent filesystem snapshots are available from the storage provider, prefer those for large volumes.

### Helm / Kustomize local render & validate

# Helm chart template + dry-run validation
helm template myrelease ./chart -f values.yaml --namespace $NAMESPACE | kubectl apply --dry-run=client -f -
helm lint ./chart -f values.yaml

# Kustomize build + dry-run
kustomize build cluster/homelab/$AREA/$APP | kubectl apply --dry-run=client -f -
# or using kubectl's builtin kustomize
kubectl kustomize cluster/homelab/$AREA/$APP | kubectl apply --dry-run=client -f -

# Optional schema validation
# kubeval or conftest if installed
kustomize build cluster/homelab/<area>/<app> | kubeval --strict --ignore-missing-schemas

### CRD backup & API version validation (backup before upgrades)

CRD + CR backup (recommended before controller upgrade or CRD changes)
# Backup CRD definitions
kubectl get crd $CRD_NAME -o yaml > crd-$CRD_NAME-backup-$(date +%Y%m%d%H%M).yaml
# Backup all CRs of a kind (namespace-scoped example)
kubectl -n $NAMESPACE get $KIND -o yaml > crs-$KIND-$NAMESPACE-backup-$(date +%Y%m%d%H%M).yaml
# For cluster-scoped CRs: kubectl get <kind> -A -o yaml > crs-<kind>-all-backup-$(date +%Y%m%d%H%M).yaml

Restore example (CRD must exist before CRs that use it)
# Apply CRD first
kubectl apply -f crd-$CRD_NAME-backup-YYYYMMDDHHMM.yaml
# Then apply CRs
kubectl -n $NAMESPACE apply -f crs-$KIND-$NAMESPACE-backup-YYYYMMDDHHMM.yaml

Validation & checks
- Confirm CRD versions and served/stored versions: kubectl get crd <crd-name> -o yaml | yq -P .spec.versions
- Check API discovery for the kind: kubectl api-resources | grep -i <kind>
- Before controller upgrade, backup CRD and CRs and store artifacts off-cluster (git-annex/S3) with checksums.
- If controller introduces API changes, follow the controller upgrade notes and migration steps for CRs (field rename, version migration).

# List CRDs and check the controller-provided group/version
kubectl get crd | grep -E "(helm|kustomization|sources)" || true
kubectl get crd <name> -o yaml | yq -P .spec.versions

# Check the API resources available in the cluster for a CRD kind
kubectl api-resources | grep -i <kind>

# If upgrading controllers, verify expected CRD versions are present before applying new controller manifests.

### ImagePull / CrashLoopBackOff troubleshooting (expanded)

Quick checks
kubectl -n $NAMESPACE describe pod $POD
kubectl -n $NAMESPACE get events --sort-by='.lastTimestamp'

ImagePullBackOff specific checks & credential verification
1) Verify image and tag locally:
   - docker pull <registry>/<repo>:<tag> || true
   - skopeo inspect docker://<registry>/<repo>:<tag> || true

2) Check imagePullSecrets and re-create if necessary:
   - kubectl -n <namespace> get secret <image-pull-secret> -o yaml || true
   - To recreate (example):
     kubectl -n <namespace> delete secret <image-pull-secret> || true
    # Recommended (safe): create from an existing docker config.json (preferred to avoid inline secrets)
    # 1) run `docker login <registry>` on your operator machine or populate ~/.docker/config.json securely
    # 2) create the kubernetes secret from that file (keeps credentials out of shell history)
    kubectl -n <namespace> create secret generic <image-pull-secret> \
      --from-file=.dockerconfigjson=$HOME/.docker/config.json --type=kubernetes.io/dockerconfigjson

    # Alternative (interactive, avoids shell history): prompt for password and unset it immediately
    # read -rsp "Docker password: " PASS; \
    # kubectl -n <namespace> create secret docker-registry <image-pull-secret> --docker-server=<registry> --docker-username=<user> --docker-password="$PASS" --docker-email=<email>; \
    # unset PASS

   - Update Kustomize/Helm values to reference the correct secret name and reconcile the HelmRelease/Kustomization.

3) Verify registry credentials from operator machine (skopeo with creds):
   - skopeo inspect --creds '<user>:<pass>' docker://<registry>/<repo>:<tag>
   - docker login <registry> && docker pull <registry>/<repo>:<tag>

CrashLoopBackOff specific checks & node runtime verification
- Get previous logs: kubectl -n <namespace> logs <pod> -c <container> --previous

- Node runtime checks (helpful when containers fail at runtime due to node issues):
  - Check container runtime status on node (containerd example):
    ssh <node>
    sudo crictl ps -a || sudo crictl status || true
    sudo systemctl status containerd || true
  - For Docker nodes: sudo docker ps -a && sudo docker info || true

Quick live-test: run a debug pod with the same image to reproduce
kubectl -n <namespace> run debug-try --image=<registry>/<repo>:<tag> --restart=Never --command -- sleep 3600
kubectl -n <namespace> logs debug-try || true
kubectl -n <namespace> delete pod debug-try || true

Additional guidance
- If the imagePullSecret is updated, rotate pods by restarting Deployments/StatefulSets to pick up the secret.
  kubectl -n <namespace> rollout restart deployment/<deployment>
- If pods on a node repeatedly fail to start, cordon the node and test on another node:
  kubectl cordon <node>
  kubectl drain <node> --ignore-daemonsets --delete-local-data --force

- For persistent auth issues, check the registry IP/DNS from cluster nodes and operator machine to rule out DNS/VPC firewall issues.
### Pre-commit hooks (repo quality and safety)

# Run hooks only for changed files
pre-commit run --files <changed-files>

# Run all hooks locally (slower but catches everything)
pre-commit run --all-files

# If a hook fails, fix the code and re-run the specific hook
pre-commit run <hook-id> --files <changed-files>


## Failure & Recovery Notes (quick references)

- Controller stuck reconciling due to bad manifest: suspend the Kustomization, revert Git commit, reconcile the source and resume.
  - flux suspend kustomization <name> -n flux-system
  - git revert <bad-commit>
  - git push && flux reconcile source git flux-system -n flux-system && flux resume kustomization <name> -n flux-system

- Secret decrypted accidentally committed: rotate secrets' recipients and re-encrypt; rotate credentials used by humans and machines that could have read the plaintext; treat as an incident.

- PVC data loss or corruption: restore from the last valid PVC backup (see PVC backup & restore above). If the PVC is a database backend, restore from the application dump, not raw filesystem copy where possible.

- ImagePull auth failure: verify the registry credentials, re-create imagePullSecret with `kubectl create secret docker-registry` and update the kustomization/helm values with the new secret name and reconcile.


Appendix: quick example (Home Assistant PVC backup)

# Backup
export NS=default
export PVC=hass-config
kubectl -n $NS apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hass-pvc-backup
spec:
  containers:
  - name: backup
    image: alpine:3.18
    command: ["sleep","3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: $PVC
  restartPolicy: Never
EOF

kubectl -n $NS exec hass-pvc-backup -- tar czf /tmp/hass-backup.tgz -C /data .
kubectl -n $NS cp hass-pvc-backup:/tmp/hass-backup.tgz ./hass-backup-$(date +%Y%m%d%H%M).tgz
kubectl -n $NS delete pod hass-pvc-backup

# Restore (reverse)

# end of runbook
