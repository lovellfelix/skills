# Proxmox Template Rollback

This document describes safe rollback approaches when a new Proxmox template or templateID causes failures.

Options

1) Revert cluster manifest (quick revert)
- If the change was a manifest-only update (templateID or storage), open a PR that restores the previous templateID and storage values.
- Apply the manifest via your GitOps process. This is low-risk and recommended when templates are incompatible.

2) Rollback individual VMs using Proxmox VM snapshots
- If VM snapshots exist for the problematic VMs, you can roll them back via the Proxmox UI or CLI:
  - qm listsnapshot <vmid>
  - qm rollback <vmid> <snapshotname>
- This is a VM-level rollback and preserves the older disk state; it may not fix config drift at the Cluster API layer.

3) Recreate VMs from previous template
- If you have a previous working template ID, update the manifest to point to it and recreate the affected machines (scale down/up, or replace Machines in Cluster API).

4) Full template revert and validation
- Restore the prior template to the node storage (re-import), and validate using scripts/template-validate.sh locally before updating the manifest.

Post-rollback steps
- After rollback, capture an etcd snapshot and validate workload health
- Reconcile Cluster API resources if machines were recreated
- Document the root cause and mark the template as invalid in the builder systems

Best practice
- Always validate templates locally before updating manifests
- Keep a documented mapping of templateID -> builder job/artifact
- Preserve a chain of known-good templateIDs in case of urgent reversion

See also: docs/preflight-checklist.md and scripts/template-validate.sh
