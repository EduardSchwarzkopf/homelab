# ADR-003: Storage Strategy (Longhorn)

## Status
**Accepted**

## Context

### Problem Statement
The Kubernetes cluster requires persistent storage for stateful applications (databases, document management, caches). The choice of storage solution is critical because it affects:

- Data durability and reliability
- Application performance and latency
- Operational complexity and maintenance
- Scalability and capacity planning
- Backup and disaster recovery capabilities
- Cost and resource utilization
- Vendor lock-in and portability

### Constraints and Assumptions

**Constraints:**
- Must run on Kubernetes cluster (Talos Linux)
- Must support persistent volumes (PVC)
- Must work with Proxmox VE storage pools
- Must support replication for data redundancy
- Must support snapshots for backup
- Must be suitable for homelab scale (100-500 GB)
- Must integrate with OpenTofu for provisioning
- Must support multiple access modes (RWO, RWX)

**Assumptions:**
- Data durability is more important than raw performance
- Replication is preferred over RAID for redundancy
- Snapshots will be used for backup strategy
- Storage will grow incrementally as needs increase
- Kubernetes-native storage is preferred

### Requirements That Influenced the Decision

1. **Data Durability**: Replicated storage for fault tolerance
2. **Kubernetes Native**: Integrated with Kubernetes API
3. **Distributed Architecture**: No single point of failure
4. **Snapshot Support**: Point-in-time recovery capability
5. **Scalability**: Easy to add more storage nodes
6. **Operational Simplicity**: Minimal manual intervention
7. **Cost Effectiveness**: Efficient resource utilization
8. **Backup Integration**: Easy integration with backup systems

## Decision

**Chosen: Longhorn**

Longhorn was selected as the persistent storage solution for this homelab infrastructure.

### Key Factors That Led to This Choice

#### 1. Kubernetes-Native Architecture
- **Longhorn**:
  - Designed specifically for Kubernetes
  - Uses Kubernetes API for management
  - Native PersistentVolume support
  - StorageClass for dynamic provisioning
  - Integrated with kubectl
  
- **Ceph**:
  - General-purpose distributed storage
  - Requires separate cluster management
  - More complex integration
  - Steeper learning curve
  
- **NFS**:
  - Not Kubernetes-native
  - Requires external NFS server
  - No built-in replication
  - Single point of failure

**Impact**: Longhorn provides seamless Kubernetes integration without external dependencies.

#### 2. Distributed Replication
- **Longhorn**:
  - Built-in replication (configurable: 1-3 replicas)
  - Automatic failover
  - Data spread across nodes
  - No RAID complexity
  - Transparent to applications
  
- **Local Storage**:
  - No replication
  - Single node failure = data loss
  - Not suitable for production
  
- **NFS**:
  - No built-in replication
  - Requires external RAID
  - Single point of failure

**Impact**: Longhorn provides data redundancy without RAID complexity.

#### 3. Snapshot and Backup Support
- **Longhorn**:
  - Built-in snapshot capability
  - Point-in-time recovery
  - Incremental snapshots
  - Easy backup integration
  - Snapshot scheduling
  
- **Ceph**:
  - Snapshot support but more complex
  - Requires additional tools
  - Steeper learning curve
  
- **NFS**:
  - No built-in snapshots
  - Requires external backup tools
  - More complex backup strategy

**Impact**: Longhorn provides easy backup and recovery without additional tools.

#### 4. Operational Simplicity
- **Longhorn**:
  - Simple installation (Helm chart)
  - Minimal configuration needed
  - Web UI for management
  - Easy to understand
  - Good documentation
  
- **Ceph**:
  - Complex installation
  - Many configuration options
  - Steep learning curve
  - Requires expertise
  
- **OpenEBS**:
  - Multiple storage engines
  - More complex configuration
  - Steeper learning curve

**Impact**: Longhorn requires minimal operational overhead.

#### 5. Resource Efficiency
- **Longhorn**:
  - Lightweight agents on nodes
  - Minimal memory footprint
  - Efficient replication
  - Good for homelab scale
  
- **Ceph**:
  - Requires dedicated nodes
  - Higher resource overhead
  - Better for large deployments
  
- **NFS**:
  - Requires external server
  - Additional VM needed
  - More resource overhead

**Impact**: Longhorn is efficient for homelab scale.

#### 6. Scalability
- **Longhorn**:
  - Easy to add new nodes
  - Automatic rebalancing
  - Scales from 1 to many nodes
  - No cluster size limits
  
- **Ceph**:
  - Requires minimum 3 nodes
  - More complex scaling
  - Better for large clusters
  
- **NFS**:
  - Scales with server capacity
  - Single point of failure

**Impact**: Longhorn scales smoothly from small to large deployments.

#### 7. Community and Ecosystem
- **Longhorn**:
  - CNCF project (Incubating)
  - Growing community
  - Good documentation
  - Active development
  - Rancher backing
  
- **Ceph**:
  - Mature project
  - Large community
  - More resources available
  - More complex
  
- **OpenEBS**:
  - CNCF project
  - Growing community
  - Multiple storage engines

**Impact**: Longhorn has sufficient community support with simpler approach.

#### 8. Cost Effectiveness
- **Longhorn**:
  - Open-source (Apache 2.0)
  - No licensing costs
  - Minimal resource overhead
  - Good for homelab
  
- **Ceph**:
  - Open-source but complex
  - Requires more resources
  - Higher operational cost
  
- **Proprietary Solutions**:
  - Licensing costs
  - Vendor lock-in
  - Not suitable for homelab

**Impact**: Longhorn is cost-effective for homelab deployments.

## Consequences

### Positive

#### 1. Data Redundancy
- **Benefit**: Automatic replication across nodes
- **Impact**: Protection against node failures
- **Timeline**: Immediate and ongoing

#### 2. Easy Backup and Recovery
- **Benefit**: Built-in snapshot capability
- **Impact**: Simple point-in-time recovery
- **Timeline**: Immediate and ongoing

#### 3. Operational Simplicity
- **Benefit**: Minimal configuration and management
- **Impact**: Reduced operational burden
- **Timeline**: Immediate and ongoing

#### 4. Kubernetes Integration
- **Benefit**: Native Kubernetes API integration
- **Impact**: Familiar tools and workflows
- **Timeline**: Immediate and ongoing

#### 5. Scalability
- **Benefit**: Easy to add storage capacity
- **Impact**: Simple cluster growth
- **Timeline**: Immediate and ongoing

#### 6. Cost Effectiveness
- **Benefit**: Open-source, minimal resource overhead
- **Impact**: Low total cost of ownership
- **Timeline**: Immediate and ongoing

#### 7. Web UI
- **Benefit**: User-friendly management interface
- **Impact**: Easier troubleshooting and monitoring
- **Timeline**: Immediate and ongoing

#### 8. Community Support
- **Benefit**: Growing community and documentation
- **Impact**: Help available when needed
- **Timeline**: Immediate and ongoing

### Negative

#### 1. Performance Overhead
- **Drawback**: Replication adds network overhead
- **Impact**: Slightly higher latency than local storage
- **Mitigation**: Acceptable for homelab workloads; can tune replication

#### 2. Storage Efficiency
- **Drawback**: Replication uses more disk space
- **Impact**: 2x or 3x storage overhead for replicated data
- **Mitigation**: Plan storage capacity accordingly; use compression

#### 3. Network Dependency
- **Drawback**: Replication depends on network performance
- **Impact**: Network issues affect storage performance
- **Mitigation**: Use dedicated storage network if needed; monitor network

#### 4. Smaller Community than Ceph
- **Drawback**: Fewer users and resources than Ceph
- **Impact**: Fewer Stack Overflow answers for edge cases
- **Mitigation**: Community is growing; documentation is good

#### 5. Limited to Kubernetes
- **Drawback**: Cannot be used outside Kubernetes
- **Impact**: Not suitable for non-Kubernetes workloads
- **Mitigation**: Use containers for all workloads

#### 6. Snapshot Storage
- **Drawback**: Snapshots consume additional storage
- **Impact**: Need to plan for snapshot retention
- **Mitigation**: Implement snapshot retention policies

### Risks and Mitigation

#### Risk 1: Data Corruption
**Risk**: Replication may propagate data corruption
**Probability**: Low
**Impact**: Data loss across all replicas
**Mitigation**:
- Regular backups to external storage
- Snapshot retention for point-in-time recovery
- Monitor data integrity
- Test recovery procedures regularly

#### Risk 2: Network Partition
**Risk**: Network issues may cause replication failures
**Probability**: Medium
**Impact**: Reduced redundancy during network issues
**Mitigation**:
- Monitor network health
- Use dedicated storage network if possible
- Implement network policies
- Test failover scenarios

#### Risk 3: Storage Capacity
**Risk**: Storage may fill up unexpectedly
**Probability**: Medium
**Impact**: Applications unable to write data
**Mitigation**:
- Monitor storage usage
- Implement storage quotas
- Plan capacity growth
- Implement cleanup policies

#### Risk 4: Performance Degradation
**Risk**: Replication may impact application performance
**Probability**: Low
**Impact**: Slower application response times
**Mitigation**:
- Monitor performance metrics
- Tune replication settings
- Use local caching where appropriate
- Consider performance requirements

#### Risk 5: Upgrade Complexity
**Risk**: Longhorn upgrades may cause issues
**Probability**: Low
**Impact**: Storage unavailability during upgrade
**Mitigation**:
- Test upgrades in sandbox environment
- Plan upgrades during maintenance windows
- Maintain backups before upgrades
- Monitor upgrade process

## Alternatives Considered

### Alternative 1: Ceph
**Pros:**
- Mature, battle-tested project
- Highly scalable
- Multiple storage types (block, object, file)
- Large community
- Enterprise support available

**Cons:**
- Complex installation and configuration
- Requires minimum 3 nodes
- Steep learning curve
- Higher resource overhead
- Overkill for homelab scale
- More operational burden

**Why Rejected**: Ceph is over-engineered for homelab scale. Longhorn provides sufficient functionality with much simpler operations.

### Alternative 2: OpenEBS
**Pros:**
- Multiple storage engines
- Flexible architecture
- Good for different use cases
- CNCF project

**Cons:**
- More complex than Longhorn
- Multiple storage engines to choose from
- Steeper learning curve
- Less mature than Ceph
- Smaller community than Longhorn

**Why Rejected**: While capable, OpenEBS adds unnecessary complexity. Longhorn's simpler approach is better for homelab.

### Alternative 3: NFS (Network File System)
**Pros:**
- Simple and well-understood
- Works with any OS
- Good for shared storage
- Minimal overhead

**Cons:**
- No built-in replication
- Single point of failure
- No snapshots
- Requires external NFS server
- Not Kubernetes-native
- Performance limitations

**Why Rejected**: NFS lacks replication and snapshots. Single point of failure makes it unsuitable for production workloads.

### Alternative 4: Local Storage
**Pros:**
- Best performance
- No network overhead
- Simple to understand
- No additional tools needed

**Cons:**
- No replication
- Single node failure = data loss
- Not suitable for production
- No redundancy
- Difficult to migrate

**Why Rejected**: Lack of replication makes it unsuitable for production workloads. Data loss risk is unacceptable.

### Alternative 5: Cloud Storage (AWS EBS, Azure Disks, etc.)
**Pros:**
- Managed by cloud provider
- High availability built-in
- Automatic backups
- Excellent support

**Cons:**
- Requires cloud provider
- Vendor lock-in
- Not suitable for on-premises
- Higher cost
- Less control

**Why Rejected**: Incompatible with on-premises Proxmox infrastructure. Would require complete rewrite for different platform.

### Alternative 6: Rook (Ceph on Kubernetes)
**Pros:**
- Ceph on Kubernetes
- Automated deployment
- Good integration

**Cons:**
- Still requires Ceph complexity
- Requires minimum 3 nodes
- Higher resource overhead
- Steeper learning curve
- Overkill for homelab

**Why Rejected**: Rook simplifies Ceph deployment but doesn't address underlying complexity. Longhorn is simpler.

## Comparison Matrix

| Criteria              | Longhorn  | Ceph        | OpenEBS   | NFS       | Local       |
| --------------------- | --------- | ----------- | --------- | --------- | ----------- |
| **Kubernetes Native** | ✅ Yes     | ⚠️ Partial   | ✅ Yes     | ❌ No      | ✅ Yes       |
| **Replication**       | ✅ Yes     | ✅ Yes       | ✅ Yes     | ❌ No      | ❌ No        |
| **Snapshots**         | ✅ Yes     | ✅ Yes       | ⚠️ Limited | ❌ No      | ❌ No        |
| **Simplicity**        | ✅ Easy    | ❌ Complex   | ⚠️ Medium  | ✅ Easy    | ✅ Easy      |
| **Scalability**       | ✅ Good    | ✅ Excellent | ✅ Good    | ⚠️ Limited | ❌ Poor      |
| **Performance**       | ⚠️ Good    | ✅ Excellent | ✅ Good    | ⚠️ Good    | ✅ Excellent |
| **Resource Overhead** | ✅ Low     | ❌ High      | ⚠️ Medium  | ✅ Low     | ✅ Very Low  |
| **Community Size**    | ⚠️ Growing | ✅ Large     | ⚠️ Growing | ✅ Large   | ✅ Large     |
| **Learning Curve**    | ✅ Easy    | ❌ Steep     | ⚠️ Medium  | ✅ Easy    | ✅ Easy      |
| **Homelab Suitable**  | ✅ Yes     | ❌ No        | ⚠️ Maybe   | ⚠️ Limited | ⚠️ Limited   |

## References

### Longhorn Documentation
- [Longhorn Official Documentation](https://longhorn.io/docs/)
- [Longhorn GitHub Repository](https://github.com/longhorn/longhorn)
- [Longhorn Architecture](https://longhorn.io/docs/latest/concepts/)

### Kubernetes Storage
- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Kubernetes Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

### Industry References
- [Backup and Recovery Best Practices](https://www.veeam.com/blog/backup-best-practices.html)

---

**Decision Date**: November 2025
**Last Updated**: November 6, 2025  
**Status**: Accepted and Implemented  
**Related Components**: Longhorn deployment in `kubernetes/bootstrap/resources/longhorn/`
