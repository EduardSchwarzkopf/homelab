# Homelab Operations Guide

> Comprehensive guide to monitoring, maintaining, and operating the homelab infrastructure.

**Table of Contents**
- [Monitoring & Observability](#monitoring--observability)
- [Maintenance Procedures](#maintenance-procedures)
- [Disaster Recovery](#disaster-recovery)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Runbooks](#runbooks)
- [Escalation Procedures](#escalation-procedures)

---

## Monitoring & Observability

### VM & Application Monitoring (Ansible + Podman)

**Primary tools**: Proxmox VE web UI for VM health; SSH into individual VMs for application-level inspection.

**VM Health**:
- Check VM status, CPU, memory, and disk usage via the Proxmox web UI or `qm list` on the Proxmox host
- Review VM console output for boot errors or kernel panics

**Container Health**:
```bash
# List running containers on a VM
podman ps

# Check container logs
podman logs <container-name>

# Check systemd service status (containers are managed as systemd services via Quadlet)
systemctl status <service-name>
journalctl -u <service-name> -f
```

**Database Health**:
```bash
# Check PostgreSQL is accepting connections
pg_isready -h localhost

# Review PostgreSQL logs via the container
podman logs <postgres-container>
```

**ZFS Storage Health**:
```bash
# Check pool status and health
zpool status

# Check dataset usage
zfs list

# Check for scrub errors
zpool status -v
```

---

### Kubernetes Monitoring

**Primary tools**: `k9s` for interactive cluster monitoring; ArgoCD UI for application sync status.

**Node Health**:
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl top nodes
```

**Cluster Health**:
```bash
kubectl cluster-info
kubectl get pods -A
kubectl top pods -A
```

**Storage Health**:
```bash
# Check Longhorn components
kubectl get pods -n longhorn-system

# Check PVC status across all namespaces
kubectl get pvc -A

# Access the Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

**Network Health**:
```bash
# Check ingress resources
kubectl get ingress -A

# Check Cilium pod status
kubectl get pods -n kube-system -l k8s-app=cilium

# Check MetalLB allocations
kubectl get svc -A --field-selector spec.type=LoadBalancer
```

**ArgoCD Sync Status**:
```bash
# List all ArgoCD applications and their sync state
kubectl get applications -n argocd

# Describe a specific application
kubectl describe application <app-name> -n argocd
```

---

### Backup Monitoring

**Check Backup Status**:
```bash
# List all backups in PBS
proxmox-backup-client list

# Verify a specific backup
proxmox-backup-client verify <backup-id>
```

- Backup frequency targets: daily (Tier 1), weekly (Tier 2), monthly (Tier 3), quarterly (Tier 4)
- Check PBS storage usage regularly to ensure capacity headroom

**See**: [BACKUP.md](operations/BACKUP.md) for detailed procedures and tier definitions.

---

### Alerting

No custom alerting is currently configured. Monitoring is done manually via k9s, the Proxmox UI, and ArgoCD.

**Recommended future alerts**:
- Node not ready / disk or memory pressure
- Pod in `CrashLoopBackOff` or pending for more than 5 minutes
- Longhorn replica degraded or volume unhealthy
- PVC usage above 80% / 95%
- PBS backup job failure or missed schedule
- PBS storage above 80%

---

## Maintenance Procedures

### Regular Maintenance Schedule

**Daily**: Review cluster and VM health; confirm backup completion notifications.

**Weekly**: Check for pending OS and application updates; verify backup integrity; review ZFS scrub results; review security logs.

**Monthly**: Apply system component updates; test a restore from backup on non-critical data; review capacity planning.

**Quarterly**: Major version updates; comprehensive security audit; disaster recovery drill.

---

### VM Maintenance (Ansible-managed)

Prefer redeploying VMs over in-place updates where possible. For minor package updates, Ansible handles idempotent re-application:

```bash
# Re-run the base configuration playbook against a specific host
ansible-playbook -i ansible/inventory playbooks/setup.yml --limit <hostname>

# Run a specific app playbook
ansible-playbook -i ansible/inventory playbooks/apps.yml --limit <hostname>
```

For OS-level maintenance that requires a reboot, snapshot the VM in Proxmox first, reboot, and verify application health before removing the snapshot.

---

### Kubernetes Node Maintenance

**Preferred approach — Redeploy via IaC**:

Rather than patching nodes in place, the preferred approach is to destroy and reprovision the node using OpenTofu. This guarantees a clean, reproducible state and leverages the immutable infrastructure model.

```bash
# Destroy the node
cd tofu/
tofu destroy -target=<node_resource>

# Provision a fresh node
tofu apply -target=<node_resource>

# Confirm the node joined the cluster
kubectl get nodes
```

**Alternative — Talos upgrade** (when a full redeploy is not practical):

Use `talosctl upgrade` to perform an in-place OS upgrade. Check the Talos documentation for the correct image reference for the target version before running.

After any node operation, verify all pods are running and Longhorn volumes are healthy before proceeding.

---

### Storage Maintenance

**Longhorn**:
```bash
# Confirm all Longhorn pods are healthy before and after maintenance
kubectl get pods -n longhorn-system

# Use the Longhorn UI to monitor volume replica health during node operations
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

**ZFS** (run on Proxmox host or NAS VM):
```bash
# Weekly pool scrub — schedule via cron
zpool scrub <pool-name>

# Check scrub results
zpool status <pool-name>

# Monitor dataset usage
zfs list -r <pool-name>
```

---

### Backup Maintenance

```bash
# List all backups
proxmox-backup-client list

# Verify a specific backup's integrity
proxmox-backup-client verify <backup-id>

# Remove a backup manually (respect retention policies before doing this)
proxmox-backup-client forget <backup-id>
```

Retention policies are configured in PBS. Manual removal should only be done outside of policy in exceptional circumstances.

---

## Disaster Recovery

### Recovery Objectives

| Tier              | RPO      | RTO      | Backup Schedule | Example Data             |
| ----------------- | -------- | -------- | --------------- | ------------------------ |
| Tier 1 (Critical) | 24 hours | 4 hours  | Daily           | Production databases     |
| Tier 2 (Standard) | 7 days   | 24 hours | Weekly          | Application state        |
| Tier 3 (Dev)      | 30 days  | 48 hours | Monthly         | Dev/staging environments |
| Tier 4 (Cache)    | 90 days  | 1 week   | Quarterly       | Regenerable data         |

### Backup & Recovery Procedures

**See**: [BACKUP.md](operations/BACKUP.md) for detailed restore procedures per tier.

---

### Disaster Recovery Scenarios

#### Scenario 1: Single VM Failure (Ansible-managed)

**Impact**: Applications on the failed VM are unavailable.

**Recovery**:
1. Restore the VM from the most recent PBS backup, or redeploy via OpenTofu and re-run Ansible
2. Verify all containers started successfully (`podman ps`)
3. Verify application health via Nginx Proxy Manager

**Time**: 15–45 minutes depending on data volume

---

#### Scenario 2: Single Kubernetes Node Failure

**Impact**: Pods on the failed node are unavailable. With a single worker node, rescheduling is not possible until the node is restored.

**Recovery**:
1. Redeploy the node using OpenTofu (see [Node Recovery Runbook](#node-recovery-runbook))
2. Verify Longhorn volumes reattach and replicas are healthy
3. Verify all pods are running

**Time**: 10–20 minutes

---

#### Scenario 3: Storage Failure

**Impact**: Loss of persistent data for affected applications.

**Recovery**:
1. Check whether a Longhorn snapshot can be used for recovery (preferred — no data loss since last snapshot)
2. If not, restore from the PBS backup appropriate to the data's tier
3. Verify data integrity before resuming the application

**Time**: 15–60 minutes depending on data volume

**Runbook**: [Storage Recovery Runbook](#storage-recovery-runbook)

---

#### Scenario 4: Control Plane Failure

**Impact**: Kubernetes API is unavailable; running pods continue serving traffic but cannot be managed.

**Recovery**:
1. Redeploy the control plane node via OpenTofu
2. Verify `kubectl` access is restored
3. Verify all workloads are in the expected state

**Time**: 15–30 minutes

**Runbook**: [Control Plane Recovery Runbook](#control-plane-recovery-runbook)

---

#### Scenario 5: Complete Cluster Rebuild

**Impact**: All Kubernetes-managed services unavailable.

**Recovery**:
1. Provision new nodes via OpenTofu
2. Bootstrap cluster components (`kubernetes/bootstrap/`)
3. Allow ArgoCD to sync applications from Git
4. Restore persistent data from PBS backups
5. Verify all applications are healthy

**Time**: 1–2 hours

**Runbook**: [Cluster Recovery Runbook](#cluster-recovery-runbook)

---

### Testing Disaster Recovery

Full disaster recovery drills are not performed regularly given homelab scale. The following lighter-weight verification is done instead:

- **Backup integrity**: Run `proxmox-backup-client verify` on a sample of recent backups monthly
- **Restore test**: Test restore of non-critical data (Tier 3 or Tier 4) quarterly
- **Runbook review**: Review runbooks quarterly and update any steps that have drifted

---

## Troubleshooting Guide

### VM / Container Issues

**Problem**: Container not starting
```bash
# Check systemd service status
systemctl status <service-name>
journalctl -u <service-name> --no-pager -n 50

# Check container logs directly
podman logs <container-name>

# Inspect the container for misconfiguration
podman inspect <container-name>
```

**Problem**: Application not reachable via Nginx Proxy Manager
- Confirm the container is running (`podman ps`)
- Confirm the Nginx Proxy Manager proxy host is configured and the upstream port matches
- Check the NPM container logs for proxy errors

**Problem**: Database connection refused
```bash
# Verify PostgreSQL is listening
pg_isready -h localhost -p 5432

# Check the PostgreSQL container is running
podman ps | grep postgres

# Check PostgreSQL logs
podman logs <postgres-container-name>
```

---

### Kubernetes Issues

**Problem**: Pod stuck in Pending
```bash
# Check events for scheduling failures
kubectl describe pod <pod-name> -n <namespace>

# Check available node resources
kubectl top nodes
kubectl describe node <node-name>

# Check PVC binding (common cause)
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc-name> -n <namespace>
```

**Problem**: Pod in CrashLoopBackOff
```bash
# Check current and previous container logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Check pod events and resource limits
kubectl describe pod <pod-name> -n <namespace>
```

**Problem**: Node not Ready
```bash
kubectl describe node <node-name>

# Check kubelet logs via talosctl
talosctl -n <node-ip> logs kubelet

# Reboot the node as a last resort
talosctl -n <node-ip> reboot
```

**Problem**: PVC stuck in Pending
```bash
# Check storage class exists
kubectl get storageclass

# Check Longhorn pods are healthy
kubectl get pods -n longhorn-system

# Describe the PVC for events
kubectl describe pvc <pvc-name> -n <namespace>
```

**Problem**: Application out of sync in ArgoCD
```bash
# Check sync status and any error messages
kubectl describe application <app-name> -n argocd

# Trigger a manual sync
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {}}}'
```

**Problem**: External traffic not reaching an application
```bash
# Check ingress resource exists and has an address assigned
kubectl get ingress -A

# Check ingress-nginx pods are running
kubectl get pods -n ingress-nginx

# Check MetalLB assigned an IP to the LoadBalancer service
kubectl get svc -n ingress-nginx
```

---

## Runbooks

### Node Recovery Runbook

**Objective**: Restore a failed Kubernetes node using Infrastructure as Code.

1. Confirm the node is unavailable:
   ```bash
   kubectl get nodes
   ```

2. Destroy the failed node resource in OpenTofu:
   ```bash
   cd tofu/
   tofu destroy -target=<node_resource>
   ```

3. Provision a replacement node:
   ```bash
   tofu apply -target=<node_resource>
   ```

4. Confirm the new node joined and is Ready:
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

5. Confirm all pods are running and no pods are stuck Pending:
   ```bash
   kubectl get pods -A
   ```

6. Confirm Longhorn volume replicas are healthy via the Longhorn UI or:
   ```bash
   kubectl get volumes -n longhorn-system
   ```

**Expected duration**: 10–20 minutes
**Success criteria**: Node shows Ready; all pods running; Longhorn volumes healthy.

---

### Storage Recovery Runbook

**Objective**: Recover from a persistent storage failure.

1. Identify the affected PVC and its Longhorn volume:
   ```bash
   kubectl describe pvc <pvc-name> -n <namespace>
   kubectl get volumes -n longhorn-system
   ```

2. Check whether a usable Longhorn snapshot exists (via the Longhorn UI). If so, restore from the snapshot — this is the fastest path with the least data loss.

3. If no usable snapshot exists, restore from the PBS backup appropriate to the data's tier. See [BACKUP.md](operations/BACKUP.md) for restore procedures.

4. After restore, verify data integrity by reviewing application logs:
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

5. Restart the application if needed:
   ```bash
   kubectl rollout restart deployment/<deployment-name> -n <namespace>
   ```

**Expected duration**: 15–60 minutes depending on data volume
**Success criteria**: PVC bound; application running; data accessible and consistent.

---

### Control Plane Recovery Runbook

**Objective**: Restore a failed Kubernetes control plane node.

1. Confirm control plane is unreachable:
   ```bash
   kubectl get nodes -l node-role.kubernetes.io/control-plane
   ```

2. Destroy and reprovision via OpenTofu:
   ```bash
   cd tofu/
   tofu destroy -target=<controlplane_resource>
   tofu apply -target=<controlplane_resource>
   ```

3. Verify API access and cluster health:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods -A
   ```

**Expected duration**: 15–30 minutes
**Success criteria**: API server responding; all nodes Ready; all pods running.

---

### Cluster Recovery Runbook

**Objective**: Rebuild the Kubernetes cluster from scratch after a complete failure.

1. Assess the failure: determine what data is at risk and identify the recovery point from PBS.

2. Destroy all cluster resources:
   ```bash
   cd tofu/
   tofu destroy
   ```

3. Provision fresh nodes:
   ```bash
   tofu apply
   ```

4. Bootstrap cluster components:
   ```bash
   kubectl apply -k kubernetes/bootstrap/
   ```

5. Wait for ArgoCD to sync all applications from Git. Verify sync status:
   ```bash
   kubectl get applications -n argocd
   ```

6. Restore persistent data from PBS backups. See [BACKUP.md](operations/BACKUP.md) for restore procedures by tier.

7. Verify all applications are healthy and reachable.

**Expected duration**: 1–2 hours
**Success criteria**: All nodes Ready; all pods running; all applications reachable; all data restored and consistent.

---

## Escalation Procedures

### Severity Levels

| Severity      | Criteria                                   | Examples                                      |
| ------------- | ------------------------------------------ | --------------------------------------------- |
| P1 — Critical | All services unavailable or data loss      | Complete cluster failure, PBS inaccessible    |
| P2 — High     | Major service degraded or at risk          | Single node failure, storage replica degraded |
| P3 — Medium   | Single application unavailable or degraded | Pod crash, ingress misconfiguration           |
| P4 — Low      | Minor issue, no user impact                | Log noise, non-urgent update pending          |

### Escalation Path

1. **Self-service**: Check k9s, ArgoCD UI, Proxmox UI, and container logs for immediate diagnosis
2. **Runbooks**: Follow the appropriate runbook in this document or in [BACKUP.md](operations/BACKUP.md)
3. **Community resources**: Kubernetes, Talos, Longhorn, and Proxmox community forums and documentation
4. **Vendor support**: Proxmox commercial support (if applicable)

### External Resources

- [Proxmox Support](https://www.proxmox.com/en/support)
- [Kubernetes Community](https://kubernetes.io/community/)
- [Talos Linux Docs](https://www.talos.dev/latest/introduction/what-is-talos/)
- [Longhorn Docs](https://longhorn.io/docs/)
- [OpenTofu Community](https://opentofu.org/community/)

---

## References

- [BACKUP.md](operations/BACKUP.md) — Backup tier definitions, schedules, retention policies, and restore procedures
- [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture, data flows, and design decisions

---

**Last Updated**: May 2026
**Status**: Active
**Maintainer**: Eduard