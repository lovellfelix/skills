# etcd Restore Runbook

This runbook covers restoring the workload control-plane from an etcd snapshot. Use only when the control-plane is irrecoverable and you have a good snapshot.

Prerequisites
- A recent etcd snapshot file (preferably stored off-host)
- Access to control-plane node(s) or ability to run commands against the etcd pod
- Management cluster access for Cluster API operations

High-level steps
1. Stop kube-apiserver on the control-plane node(s) so the cluster does not modify etcd during restore.
2. Place the snapshot file on the control-plane host or make it available to the etcd container.
3. Run etcdctl snapshot restore with the original cluster parameters (name, initial-cluster, data-dir).
   - Example (on control-plane node):
     sudo ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd-snapshot.db \
       --data-dir /var/lib/etcd-from-snapshot
4. Update systemd unit or manifest to point to restored data-dir, or replace the pod volume
5. Start etcd and kube-apiserver and monitor logs
6. Verify cluster health: kubectl get nodes, kubectl get cs, check control-plane components

Using the Kubernetes/etcd pod path
- If your control-plane runs etcd as a pod (kube-system), you can exec into the etcd container and use:
  kubectl exec -n kube-system <etcd-pod> -- etcdctl snapshot restore - --data-dir=/var/lib/etcd-restored < snapshot-file.db
- You may need to stop kube-apiserver pods before switching the data directory.

Post-restore validation
- Validate that control-plane components are Ready and that workloads start normally
- Inspect workloads for deletion or orphaned resources
- Reconcile any Cluster API Machine objects if the topology changed during the outage

Rollback and communication
- Notify stakeholders and open a post-incident ticket with snapshot metadata and timeline
- If restore fails, consider rebuilding control-plane nodes from last-known-good templates and re-joining workers

Notes & risks
- Restoring etcd is destructive to data newer than the snapshot
- Prefer restoring to fresh control-plane nodes and re-creating join tokens rather than in-place replacement unless you fully control the sequence

See: docs/preflight-checklist.md for snapshot capture and scripts/etcd-snapshot.sh for automation of snapshot collection.
