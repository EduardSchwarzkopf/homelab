# Homelab Operations Guide

> Comprehensive guide to monitoring, maintaining, and operating the homelab infrastructure.

**Table of Contents**
- [Monitoring & Observability](#monitoring--observability)
- [Maintenance Procedures](#maintenance-procedures)
- [Disaster Recovery](#disaster-recovery)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Runbooks](#runbooks)
- [Escalation Procedures](#escalation-procedures)

---

## Monitoring & Observability

### System Monitoring

**Key Metrics to Monitor**:

Primary tool: **k9s** for cluster interaction and monitoring

1. **Node Health**
   ```bash
   # Check node status
   kubectl get nodes
   kubectl describe node <node-name>
   
   # Check node resources
   kubectl top nodes
   kubectl top pods -A
   ```

2. **Cluster Health**
   ```bash
   # Check cluster status
   kubectl cluster-info
   kubectl get componentstatuses
   
   # Check API server
   kubectl get endpoints kubernetes
   ```

3. **Storage Health**
   ```bash
   # Check Longhorn status
   kubectl get pods -n longhorn-system
   kubectl get storageclass
   kubectl get pvc -A
   
   # Check Longhorn UI
   kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
   # Access: http://localhost:8080
   ```

4. **Network Health**
   ```bash
   # Check network policies
   kubectl get networkpolicies -A
   
   # Check Cilium status
   kubectl get pods -n kube-system -l k8s-app=cilium
   
   # Test connectivity
   kubectl run -it --rm debug --image=busybox --restart=Never -- ping <pod-ip>
   ```

### Application Monitoring

**Check Application Status**:
```bash
# List all applications
kubectl get applications -A

# Check application pods
kubectl get pods -n <app-namespace>

# Check application logs
kubectl logs -n <app-namespace> <pod-name>

# Check application events
kubectl get events -n <app-namespace>
```

**Monitor Application Performance**:
```bash
# Check resource usage
kubectl top pods -n <app-namespace>

# Check pod metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods -n <app-namespace>
```

### Backup Monitoring

**Check Backup Status**:
```bash
# Check backup jobs
pvesh get /nodes/<node>/storage/<storage>/content

# Check backup logs
tail -f /var/log/proxmox-backup/proxmox-backup-proxy.log

# List backups
proxmox-backup-client list
```

**Backup Metrics**:
- Backup frequency: Daily (Tier 1), Weekly (Tier 2), Monthly (Tier 3), Quarterly (Tier 4)
- Backup duration: 5-60 minutes depending on tier
- Backup size: Varies by data volume
- Retention: 30-180 days depending on tier

**See**: [BACKUP.md](operations/BACKUP.md) for detailed backup procedures

### Alerting 

Currently, no custom alerts are configured. Monitoring is done manually via k9s and ArgoCD. Default Kubernetes alerts (if any) are the only alerts in place.

**Potential Alerts to Configure** (for future implementation):

1. **Node Alerts**
   - Node not ready
   - Node disk pressure
   - Node memory pressure
   - Node CPU pressure

2. **Pod Alerts**
   - Pod CrashLoopBackOff
   - Pod pending >5 minutes
   - Pod restart rate high

3. **Storage Alerts**
   - PVC usage >80%
   - PVC usage >95%
   - Longhorn replica degraded
   - Longhorn volume unhealthy

4. **Backup Alerts**
   - Backup job failed
   - Backup job missed
   - Backup storage >80%
   - Backup storage >95%

5. **Network Alerts**
   - Network latency high
   - Packet loss detected
   - DNS resolution failures

---

## Maintenance Procedures

### Regular Maintenance Schedule

**Daily**:
- Monitor cluster health via k9s
- Backup status notifications via email
- Monitor storage usage as needed

**Weekly**:
- Review node metrics
- Check for pending updates
- Verify backup integrity
- Review security logs

**Monthly**:
- Update system components
- Test disaster recovery
- Review capacity planning
- Audit access logs

**Quarterly**:
- Major version updates
- Comprehensive security audit
- Capacity planning review
- Disaster recovery drill

### Node Maintenance

**Preferred Approach: Redeploy Node**:

Rather than updating nodes manually, the preferred approach is to redeploy the node using Infrastructure as Code:

```bash
# Destroy old node
cd tofu/infrastructure
tofu destroy -target=module.kubernetes_node_<name>

# Provision new node
tofu apply -target=module.kubernetes_node_<name>

# Verify node joined cluster
kubectl get nodes
```

This approach leverages the power of IaC and ensures a clean, reproducible state.

**Alternative: Manual Updates** (if needed):

```bash
# Check available updates
talosctl -n <node-ip> upgrade --check

# Perform upgrade
talosctl -n <node-ip> upgrade --image ghcr.io/siderolabs/talos:v1.x.x

# Verify upgrade
talosctl -n <node-ip> version
```

### Kubernetes Component Updates

**Update Control Plane**:
```bash
# Check available versions
kubectl version

# Update via Talos
talosctl -n <control-plane-ip> upgrade --image ghcr.io/siderolabs/kubernetes:v1.x.x
```

**Update Worker Nodes**:
```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets

# Update via Talos
talosctl -n <worker-ip> upgrade --image ghcr.io/siderolabs/kubernetes:v1.x.x

# Uncordon node
kubectl uncordon <node-name>
```

### Storage Maintenance

**Longhorn Maintenance**:
```bash
# Check Longhorn status
kubectl get pods -n longhorn-system

# Update Longhorn
helm upgrade longhorn longhorn/longhorn -n longhorn-system

# Verify update
kubectl get pods -n longhorn-system
```

**ZFS Maintenance**:
```bash
# Check pool status
zpool status

# Check dataset usage
zfs list

# Scrub pool (weekly)
zpool scrub <pool-name>

# Check scrub status
zpool status <pool-name>
```

### Backup Maintenance

**Verify Backup Integrity**:
```bash
# List backups
proxmox-backup-client list

# Verify backup
proxmox-backup-client verify <backup-id>

# Check backup size
proxmox-backup-client list --output-format json | jq '.[] | {id, size}'
```

**Cleanup Old Backups**:
```bash
# Manual cleanup (respecting retention policies)
proxmox-backup-client forget <backup-id>

# Or configure automatic cleanup via retention policies
```

---

## Disaster Recovery

### Recovery Objectives

| Tier              | RPO      | RTO      | Procedure                          |
| ----------------- | -------- | -------- | ---------------------------------- |
| Tier 1 (Critical) | 24 hours | 4 hours  | Full restore from daily backup     |
| Tier 2 (Standard) | 7 days   | 24 hours | Full restore from weekly backup    |
| Tier 3 (Dev)      | 30 days  | 48 hours | Full restore from monthly backup   |
| Tier 4 (Cache)    | 90 days  | 1 week   | Full restore from quarterly backup |

### Backup & Recovery Procedures

**See**: [BACKUP.md](operations/BACKUP.md) for detailed procedures

### Disaster Recovery Scenarios

#### Scenario 1: Single Node Failure 

**Impact**: Loss of pods on failed node

**Recovery Procedure**:
1. With only one worker node, pod rescheduling is not possible
2. Redeploy the failed node using Infrastructure as Code
3. Verify node joined cluster
4. Verify all pods are running

**Time**: 5-15 minutes

**Runbook**: [Node Recovery Runbook](#node-recovery-runbook)

#### Scenario 2: Storage Failure

**Impact**: Loss of persistent data

**Recovery Procedure**:
1. Identify failed storage
2. Restore from Longhorn snapshot (if available)
3. Or restore from backup
4. Verify data integrity
5. Resume application

**Time**: 10-30 minutes

**Runbook**: [Storage Recovery Runbook](#storage-recovery-runbook)

#### Scenario 3: Control Plane Failure

**Impact**: Cluster management unavailable, but pods continue running

**Recovery Procedure**:
1. Identify failed control plane node
2. Repair or replace node
3. Rejoin to cluster
4. Verify cluster health
5. Resume normal operations

**Time**: 15-30 minutes

**Runbook**: [Control Plane Recovery Runbook](#control-plane-recovery-runbook)

#### Scenario 4: Complete Cluster Failure

**Impact**: All services unavailable

**Recovery Procedure**:
1. Restore from backup
2. Rebuild cluster from scratch
3. Restore persistent data
4. Verify all services
5. Resume normal operations

**Time**: 1-2 hours

**Runbook**: [Cluster Recovery Runbook](#cluster-recovery-runbook)

### Testing Disaster Recovery

Given the scale of the homelab and time constraints, intensive backup testing is not performed. However, backups are regularly verified for integrity and recovery procedures are documented.

**Backup Verification** (as time permits):
- Verify backup integrity via `proxmox-backup-client verify`
- Test restore procedures on non-critical data
- Document any issues found

**Recovery Procedures**:
- Documented runbooks for each tier
- Tested manually when needed
- Automated recovery via Infrastructure as Code

---

## Troubleshooting Guide

### Cluster Health Issues

**Problem**: Cluster not responding
```bash
# Check API server
kubectl cluster-info

# Check control plane nodes
kubectl get nodes -l node-role.kubernetes.io/control-plane

# Check etcd
kubectl get endpoints etcd

# Restart API server if needed
kubectl rollout restart deployment/kube-apiserver -n kube-system
```

**Problem**: Nodes not ready
```bash
# Check node status
kubectl describe node <node-name>

# Check kubelet logs
talosctl -n <node-ip> logs kubelet

# Check network connectivity
ping <node-ip>

# Reboot node if needed
talosctl -n <node-ip> reboot
```

### Pod Issues

**Monitoring Tools**: k9s and ArgoCD are also used to check pod status and application health.

**Problem**: Pod stuck in pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource availability
kubectl top nodes
kubectl describe node <node-name>

# Check storage availability
kubectl get pvc -n <namespace>

# Check network policies
kubectl get networkpolicies -n <namespace>
```

**Problem**: Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource limits
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Limits"

# Check health checks
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Liveness"
```

### Storage Issues

**Problem**: PVC stuck in pending
```bash
# Check PVC status
kubectl describe pvc <pvc-name> -n <namespace>

# Check storage class
kubectl get storageclass

# Check Longhorn status
kubectl get pods -n longhorn-system

# Check available storage
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, allocatable: .status.allocatable}'
```

**Problem**: Longhorn volume unhealthy
```bash
# Check Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# Check volume status
kubectl get volumes -n longhorn-system

# Check replica status
kubectl get replicas -n longhorn-system

# Rebuild replicas if needed
# (via Longhorn UI)
```

### Network Issues

**Problem**: Pods cannot communicate
```bash
# Check network policies
kubectl get networkpolicies -A

# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- ping <pod-ip>

# Check DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>

# Check Cilium status
kubectl get pods -n kube-system -l k8s-app=cilium
```

**Problem**: External connectivity issues
```bash
# Check ingress status
kubectl get ingress -A

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress logs
kubectl logs -n ingress-nginx <nginx-pod>

# Test ingress
curl -v http://<ingress-ip>/<path>
```

---

## Runbooks

### Node Recovery Runbook

**Objective**: Recover from single node failure

**Approach**: Use Infrastructure as Code to redeploy the node

**Steps**:

1. **Identify Failed Node**
   ```bash
   kubectl get nodes
   # Look for NotReady status
   ```

2. **Destroy Failed Node**
   ```bash
   cd tofu/infrastructure
   tofu destroy -target=module.kubernetes_node_<name>
   ```

3. **Provision New Node**
   ```bash
   tofu apply -target=module.kubernetes_node_<name>
   ```

4. **Verify Node Health**
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

5. **Verify Pods Are Running**
   ```bash
   kubectl get pods -A
   ```

**Expected Duration**: 5-15 minutes

**Success Criteria**:
- Node shows Ready status
- All pods are running
- No pending pods

---

### Storage Recovery Runbook

**Objective**: Recover from storage failure

**Prerequisites**:
- Backups are available
- Cluster is healthy

**Steps**:

1. **Identify Failed Storage**
   ```bash
   kubectl describe pvc <pvc-name>
   kubectl get pv <pv-name>
   ```

2. **Check Longhorn Status**
   ```bash
   kubectl get volumes -n longhorn-system
   kubectl get replicas -n longhorn-system
   ```

3. **Restore from Snapshot** (if available)
   ```bash
   # Via Longhorn UI
   # 1. Select volume
   # 2. Select snapshot
   # 3. Click Restore
   ```

4. **Or Restore from Backup**
   ```bash
   # Restore VM from backup
   proxmox-backup-client restore <backup-id>
   
   # Or restore PVC from backup
   # (application-specific procedure)
   ```

5. **Verify Data Integrity**
   ```bash
   # Check application logs
   kubectl logs -n <namespace> <pod-name>
   
   # Verify data consistency
   # (application-specific checks)
   ```

6. **Resume Application**
   ```bash
   # Restart pods if needed
   kubectl rollout restart deployment/<deployment-name> -n <namespace>
   ```

**Expected Duration**: 10-30 minutes

**Success Criteria**:
- PVC is bound
- Application is running
- Data is accessible

---

### Control Plane Recovery Runbook

**Objective**: Recover from control plane failure

**Approach**: Use Infrastructure as Code to redeploy the node

**Steps**:

1. **Identify Failed Control Plane Node**
   ```bash
   kubectl get nodes -l node-role.kubernetes.io/control-plane
   ```

2. **Destroy Failed Node**
   ```bash
   cd tofu/infrastructure
   tofu destroy -target=module.kubernetes_controlplane_<name>
   ```

3. **Provision New Node**
   ```bash
   tofu apply -target=module.kubernetes_controlplane_<name>
   ```

4. **Verify Cluster Health**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

5. **Verify All Services**
   ```bash
   kubectl get pods -A
   ```

**Expected Duration**: 15-30 minutes

**Success Criteria**:
- All control plane nodes are Ready
- API server is responding
- etcd is healthy

---

### Cluster Recovery Runbook

**Objective**: Recover from complete cluster failure

**Approach**: Use Infrastructure as Code to redeploy the entire cluster

**Steps**:

1. **Assess Damage**
   - Determine what data is lost
   - Identify recovery point
   - Plan recovery sequence

2. **Destroy Old Cluster**
   ```bash
   cd tofu/infrastructure
   tofu destroy
   ```

3. **Provision New Cluster**
   ```bash
   tofu apply
   ```

4. **Bootstrap Kubernetes**
   ```bash
   cd kubernetes/bootstrap
   kubectl apply -k .
   ```

5. **Restore Persistent Data**
   ```bash
   # Restore from backups
   proxmox-backup-client restore <backup-id>
   
   # Or restore PVCs from backups
   # (application-specific procedure)
   ```

6. **Restore Applications**
   ```bash
   # Sync ArgoCD
   argocd app sync <app-name>
   
   # Or manually deploy
   kubectl apply -f kubernetes/apps/
   ```

7. **Verify All Services**
   ```bash
   kubectl get pods -A
   kubectl get ingress -A
   
   # Test applications
   curl http://<app-domain>
   ```

**Expected Duration**: 1-2 hours

**Success Criteria**:
- All nodes are Ready
- All pods are running
- All applications are accessible
- All data is restored

---

## Escalation Procedures

### Severity Levels

**Critical** (P1):
- Complete cluster failure
- Data loss
- Security breach
- All services unavailable

**High** (P2):
- Single node failure
- Storage failure
- Control plane degradation
- Some services unavailable

**Medium** (P3):
- Pod crashes
- Network latency
- Performance degradation
- Single pod unavailable

**Low** (P4):
- Minor issues
- Documentation updates
- Optimization opportunities

### Escalation Path

**Level 1**: Automated monitoring and alerting
- Monitor cluster health
- Trigger alerts
- Attempt automatic recovery

**Level 2**: Manual investigation
- Check logs and metrics
- Identify root cause
- Attempt manual recovery

**Level 3**: Expert consultation
- Consult documentation
- Review decision records
- Implement fix

**Level 4**: External support
- Contact vendor support
- Consult community
- Implement workaround

### Contact Information

**Internal**:
- Infrastructure team: [contact info]
- On-call engineer: [contact info]

**External**:
- Proxmox support: https://www.proxmox.com/en/support
- Kubernetes community: https://kubernetes.io/community/
- OpenTofu community: https://opentofu.org/community/

---

## References

- [BACKUP.md](operations/BACKUP.md) - Backup procedures
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [SETUP.md](SETUP.md) - Initial setup guide
- [Kubernetes Operations](https://kubernetes.io/docs/tasks/administer-cluster/)
- [Proxmox Operations](https://pve.proxmox.com/wiki/Operations)

---

**Last Updated**: November 2025  
**Status**: Active  
**Maintainer**: Eduard
