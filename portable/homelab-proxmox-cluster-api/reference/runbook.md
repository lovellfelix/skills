# Homelab Proxmox Cluster API Runbook

## Repo Selection

- Use first: `/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/`
- Use as reference only: `/Users/lovellfelix/projects/proxmox/cluster-api/`

The migration notes mark `gitops-homelab` as the operational source of truth and the older Proxmox repo as a legacy reference.

## Access and Status

Management cluster checks:

```bash
export KUBECONFIG="$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig"
kubectl cluster-info
kubectl get pods -n capmox-system
kubectl get cluster,kubeadmcontrolplane,machines,proxmoxmachine -A -o wide
```

Full status script:

```bash
MGMT_KUBECONFIG="$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig" \
WORKLOAD_KUBECONFIG="$HOME/.kubeconfig.homelab-cluster" \
  /Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/scripts/cluster-status.sh
```

## Rebuild and Build

Build only:

```bash
/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/scripts/20-build-homelab-ha.sh \
  --mgmt-kubeconfig "$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig"
```

Full rebuild:

```bash
/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/scripts/30-rebuild-homelab-ha.sh \
  --mgmt-kubeconfig "$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig" \
  --auto-fix-boot
```

Teardown:

```bash
/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/scripts/21-teardown-homelab-ha.sh \
  --name homelab \
  --mgmt-kubeconfig "$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig" \
  --force
```

## Template Validation

Validate the current template before using it:

```bash
/Users/lovellfelix/projects/gitops-homelab/infrastructure/cluster-api/scripts/10-ensure-workload-template.sh 9002
```

What it checks:

- Proxmox SSH connectivity
- `template: 1`
- `scsi0` boot disk exists on expected storage
- cloud-init drive exists
- optional deep clone, boot, network, and SSH validation

## Create a New Template

Current detailed builder docs live in the legacy repo:

- `/Users/lovellfelix/projects/proxmox/cluster-api/01-template-builder/QUICKSTART.md`

Practical flow:

1. Review the builder config and desired Kubernetes version.
2. Build the container image and load it into the management cluster if using the job path.
3. Run the builder job.
4. Capture the new template ID from logs or Proxmox.
5. Validate the template with `10-ensure-workload-template.sh`.
6. Update `infrastructure/cluster-api/manifests/homelab-cluster.yaml` with the new `templateID` and the intended `version` fields.
7. Open a PR if requested, or apply via the build/rebuild scripts.

## Kubeadm Upgrade Workflow

Use this flow for the homelab workload cluster unless the user explicitly targets the k3s `system-upgrade` plans.

1. Build or identify a template containing the target Kubernetes bits.
2. Validate the template.
3. Edit:
   - `infrastructure/cluster-api/manifests/homelab-cluster.yaml`
4. Update:
   - `KubeadmControlPlane.spec.version`
   - `MachineDeployment.spec.template.spec.version`
   - `ProxmoxMachineTemplate.spec.template.spec.templateID` as needed
5. Review control-plane storage comments before touching storage or source-node values.
6. If asked for GitOps flow, create a PR from `gitops-homelab`.
7. If asked to execute directly, run the build or reconcile path and monitor:

```bash
export KUBECONFIG="$HOME/.kube/proxmox-capi/mgmt-cluster.kubeconfig"
kubectl get cluster,machines,proxmoxmachine -A -w
```

8. Write or refresh workload kubeconfig and verify nodes.

## Control-Plane Migration Warning

The live manifest documents an important constraint:

- control-plane disks are still on `ceph-nvme`
- etcd latency and API instability are known consequences
- do not change the shared control-plane template storage directly to `local-zfs`

Use the rolling replacement guidance in:

- `CONTROL_PLANE_LOCAL_ZFS_MIGRATION.md`
- `FIRST_CONTROL_PLANE_REPLACEMENT_PVE22.md`

## PR Workflow

When the user wants a PR:

1. Work in `/Users/lovellfelix/projects/gitops-homelab`
2. Create a branch
3. Make manifest or script changes
4. Run targeted validation commands
5. Commit with a focused message
6. Push and run `gh pr create`

Suggested PR summary points:

- why the cluster lifecycle change is needed
- what template or version changed
- what validation was run
- any rollout or storage-migration risk
