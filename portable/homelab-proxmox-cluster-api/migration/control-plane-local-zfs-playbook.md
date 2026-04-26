# Control Plane Local-ZFS Migration Playbook

This playbook captures the recommended approach for replacing control-plane storage from a shared Ceph (`ceph-nvme`) backend to `local-zfs` templates. This is a high-risk operation and should be run as a staged replacement.

Principles
- Do not modify control-plane ProxmoxMachineTemplate storage in-place for all control-plane replicas at once.
- Replace control-plane machines one-at-a-time via rolling replacement using the Cluster API (create new machine with local-zfs template, wait for Ready, then delete old machine).
- Validate each replacement thoroughly with preflight checks and snapshots.

Steps
1. Preflight
   - Run scripts/preflight.sh
   - Capture an etcd snapshot: scripts/etcd-snapshot.sh
   - Validate templates: scripts/template-validate.sh TEMPLATE_ID=<new-template> PVE_HOST=<pve> STORAGE=local-zfs
2. Create a new ProxmoxMachineTemplate or update manifest to add a new templateID referencing local-zfs (do not replace the existing template for all control-plane replicas)
3. Apply manifest change to create an additional control-plane machine (scale up control-plane by 1)
4. Wait for new control-plane machine to join and become Ready
   - Use scripts/cluster-status.sh and kubectl get kubeadmcontrolplanes,machines -A
5. Evict and delete one old control-plane machine from the Cluster API (delete the corresponding Machine object)
6. Ensure cluster remains healthy and control-plane components are Ready
7. Repeat steps 3-6 until all control-plane machines are using local-zfs
8. Once complete, remove the old template references and tidy manifests; run template validations again

Rollback
- If a replacement fails, restore the prior state by creating machines using the last-known-good templateID and rejoining them to the control plane
- Consult docs/recovery/etcd-restore.md and docs/recovery/proxmox-template-rollback.md for detailed recovery steps

Caveats
- This process assumes the builder job for the `local-zfs` template created a fully functional cloud-init-enabled image
- Network and storage performance differences between backends may surface during iteration; monitor carefully

Use the playbook as a checklist and do not shortcut the one-at-a-time replacement pattern.
