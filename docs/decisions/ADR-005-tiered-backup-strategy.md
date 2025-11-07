# ADR-005: Tiered Backup Strategy for Data VMs

## Status
**Accepted**

## Context

### Problem Statement
The homelab infrastructure requires a comprehensive backup strategy to protect data across multiple virtual machines with varying criticality levels and recovery requirements. The choice of backup strategy is critical because it affects:

- **Data Protection**: Ability to recover from data loss, corruption, or disasters
- **Recovery Time Objective (RTO)**: How quickly systems can be restored
- **Recovery Point Objective (RPO)**: How much data loss is acceptable
- **Storage Efficiency**: Cost and capacity implications of backup retention
- **Operational Complexity**: Effort required to manage and monitor backups
- **Compliance Requirements**: Meeting regulatory and business requirements
- **Scalability**: Supporting infrastructure growth without proportional cost increases
- **Disaster Recovery**: Ability to recover from catastrophic failures

A single backup pool approach treats all data equally, which is inefficient and doesn't align with industry best practices. Different data types have different criticality levels and recovery requirements:

- **Critical Production Data** (databases, backup infrastructure): Requires frequent backups and fast recovery
- **Standard Application Data** (configurations, application state): Requires regular backups with moderate recovery time
- **Development/Testing Data** (sandbox environments): Requires periodic backups with flexible recovery time
- **Regenerable Data** (caches, temporary files): Requires minimal backup frequency

Without differentiation, the infrastructure either over-invests in backup frequency for non-critical data or under-invests in protection for critical data.

### Constraints and Assumptions

**Constraints:**
- Must support multiple backup tiers with different schedules
- Must integrate with Proxmox Backup Server (PBS) infrastructure
- Must support ZFS-based storage pools
- Must be manageable via Infrastructure-as-Code (OpenTofu)
- Must support automated backup scheduling
- Must provide backup verification and integrity checks
- Must support retention policies for compliance
- Must be suitable for homelab scale (multiple VMs, 500GB-2TB total data)

**Assumptions:**
- Data durability is more important than backup frequency
- Tiered approach is more cost-effective than uniform backup strategy
- Backup infrastructure (PBS) is highly available
- Network bandwidth is sufficient for backup traffic
- Storage capacity can be planned and provisioned
- Backup jobs will be monitored and maintained
- Recovery procedures will be tested regularly
- Tier assignments will be documented and reviewed

### Requirements That Influenced the Decision

1. **Differentiated RPO/RTO**: Different data types require different recovery objectives
2. **Cost Optimization**: Reduce backup frequency for non-critical data to save storage and bandwidth
3. **Compliance Support**: Meet regulatory requirements for data retention and recovery
4. **Operational Efficiency**: Automate tier assignment and backup scheduling
5. **Scalability**: Support infrastructure growth from 2-3 VMs to 10+ VMs
6. **Disaster Recovery**: Ensure critical systems can be recovered quickly
7. **Data Integrity**: Verify backup integrity and test recovery procedures
8. **Clear Responsibility**: Each VM has explicit backup requirements and tier assignment

## Decision

**Chosen: 4-Tier Backup Strategy with Differentiated Schedules and Retention Policies**

A tiered backup strategy was selected to optimize backup frequency, retention, and storage allocation based on data criticality and recovery requirements.

### Tier Definitions

#### Tier 1: Critical Production
**Numeric ID**: 1  
**Purpose**: Production databases and critical application data  
**Backup Frequency**: Daily (24-hour retention minimum)  
**Retention Policy**: 30 days (daily backups)  
**Storage**: Premium/fast storage (zfs-longhorn)  
**Examples**: Postgres, PBS, critical application databases  
**RPO**: 24 hours (maximum acceptable data loss)  
**RTO**: 4 hours (maximum acceptable recovery time)  
**Pool ID**: `tier-1`  

**Rationale**: Critical production systems require frequent backups to minimize data loss and fast recovery to minimize downtime. Daily backups ensure no more than 24 hours of data loss. 4-hour RTO allows for rapid recovery during business hours.

#### Tier 2: Standard Application
**Numeric ID**: 2  
**Purpose**: Application data with moderate importance  
**Backup Frequency**: Weekly (7-day retention minimum)  
**Retention Policy**: 12 weeks (84 days)  
**Storage**: Standard storage (zfs-longhorn)  
**Examples**: Configuration files, application state, web application data  
**RPO**: 7 days (maximum acceptable data loss)  
**RTO**: 24 hours (maximum acceptable recovery time)  
**Pool ID**: `tier-2`  

**Rationale**: Standard application data is important but not critical. Weekly backups are sufficient for configuration and state data. 24-hour RTO allows for recovery during next business day.

#### Tier 3: Development/Testing
**Numeric ID**: 3  
**Purpose**: Development and testing environments  
**Backup Frequency**: Monthly (30-day retention minimum)  
**Retention Policy**: 3 months (90 days)  
**Storage**: Standard storage (zfs-longhorn)  
**Examples**: Sandbox VMs, development databases, test environments  
**RPO**: 30 days (maximum acceptable data loss)  
**RTO**: 48 hours (maximum acceptable recovery time)  
**Pool ID**: `tier-3`  

**Rationale**: Development and testing data is valuable for reproducibility but not critical for production. Monthly backups are sufficient. 48-hour RTO allows for recovery during next business week.

#### Tier 4: Cache/Temporary
**Numeric ID**: 4  
**Purpose**: Regenerable data, caches, temporary files  
**Backup Frequency**: Quarterly (90-day retention minimum)  
**Retention Policy**: 6 months (180 days)  
**Storage**: Standard storage (zfs-longhorn)  
**Examples**: Ollama models, temporary caches, regenerable data  
**RPO**: 90 days (maximum acceptable data loss)  
**RTO**: 1 week (maximum acceptable recovery time)  
**Pool ID**: `tier-4`  

**Rationale**: Cache and temporary data is regenerable and not critical. Quarterly backups are sufficient for disaster recovery. 1-week RTO is acceptable as data can be regenerated if needed.

### Key Factors That Led to This Choice

#### 1. Differentiated Recovery Objectives
- **Tiered Approach**:
  - Tier 1: 24-hour RPO, 4-hour RTO (critical systems)
  - Tier 2: 7-day RPO, 24-hour RTO (standard systems)
  - Tier 3: 30-day RPO, 48-hour RTO (development systems)
  - Tier 4: 90-day RPO, 1-week RTO (regenerable data)
  - Aligns backup strategy with actual business requirements
  - Avoids over-investment in non-critical data
  
- **Uniform Approach**:
  - Same backup frequency for all data
  - Treats critical and non-critical data equally
  - Wastes resources on non-critical data
  - May under-protect critical data

**Impact**: Tiered approach ensures appropriate protection level for each data type while optimizing resource usage.

#### 2. Cost Optimization
- **Tiered Approach**:
  - Reduced backup frequency for non-critical data
  - Lower storage requirements for development/test data
  - Efficient use of backup infrastructure
  - Reduced network bandwidth for non-critical backups
  - Estimated 40-50% reduction in backup storage vs. uniform approach
  
- **Uniform Approach**:
  - Same backup frequency for all data
  - Higher storage requirements
  - Inefficient resource allocation
  - Higher operational costs

**Impact**: Tiered approach reduces backup storage and bandwidth costs significantly.

#### 3. Operational Efficiency
- **Tiered Approach**:
  - Automated tier assignment through module variables
  - Consistent naming conventions for pools
  - Clear responsibility for each VM
  - Easier to monitor and maintain
  - Scalable to many VMs
  
- **Manual Approach**:
  - Manual backup scheduling for each VM
  - Inconsistent naming and configuration
  - Difficult to scale
  - Higher operational burden

**Impact**: Tiered approach enables automation and reduces operational complexity.

#### 4. Compliance and Retention
- **Tiered Approach**:
  - Different retention policies for different data types
  - Supports regulatory requirements (e.g., 30-day retention for critical data)
  - Audit trail of backup policies
  - Clear documentation of retention requirements
  
- **No Tiering**:
  - Single retention policy for all data
  - May not meet regulatory requirements
  - Difficult to justify retention policies
  - Compliance risk

**Impact**: Tiered approach supports compliance requirements and provides audit trail.

#### 5. Disaster Recovery Alignment
- **Tiered Approach**:
  - Backup strategy aligns with disaster recovery plan
  - Different recovery procedures for different tiers
  - Clear RTO/RPO targets for each system
  - Supports business continuity planning
  
- **Uniform Approach**:
  - Same recovery procedures for all systems
  - May not meet actual recovery requirements
  - Difficult to prioritize recovery efforts

**Impact**: Tiered approach ensures backup strategy supports disaster recovery objectives.

#### 6. Scalability and Growth
- **Tiered Approach**:
  - Easy to add new VMs with appropriate tier assignment
  - Scales from 2-3 VMs to 10+ VMs
  - Consistent framework for new systems
  - Reduces decision-making for new VMs
  
- **Ad-hoc Approach**:
  - Each VM requires individual backup configuration
  - Difficult to scale
  - Inconsistent policies
  - Higher operational burden

**Impact**: Tiered approach provides scalable framework for infrastructure growth.

#### 7. Storage Pool Efficiency
- **Tiered Approach**:
  - Separate pools for different backup frequencies
  - Allows optimization of storage for each tier
  - Tier 1 can use faster storage for quick recovery
  - Tier 4 can use slower, cheaper storage
  - Efficient use of storage resources
  
- **Single Pool**:
  - All backups in same pool
  - Cannot optimize for different access patterns
  - Wastes resources on fast storage for non-critical data

**Impact**: Tiered approach enables storage optimization and cost reduction.

#### 8. Monitoring and Alerting
- **Tiered Approach**:
  - Clear backup job definitions for each tier
  - Easier to monitor backup success/failure
  - Tier-specific alerting thresholds
  - Clear responsibility for each tier
  
- **Uniform Approach**:
  - Many backup jobs to monitor
  - Difficult to identify critical failures
  - No tier-specific alerting

**Impact**: Tiered approach enables better monitoring and faster incident response.

## Consequences

### Positive

#### 1. Optimized Data Protection
- **Benefit**: Each data type receives appropriate protection level
- **Impact**: Critical systems are well-protected while non-critical systems avoid over-investment
- **Timeline**: Immediate and ongoing

#### 2. Cost Reduction
- **Benefit**: Reduced backup frequency for non-critical data
- **Impact**: Lower storage costs, reduced bandwidth usage, reduced operational overhead
- **Timeline**: Immediate and ongoing (estimated 40-50% reduction in backup costs)

#### 3. Compliance Support
- **Benefit**: Different retention policies support regulatory requirements
- **Impact**: Easier compliance audits, clear audit trail of backup policies
- **Timeline**: Immediate and ongoing

#### 4. Operational Clarity
- **Benefit**: Each VM has explicit backup requirements and tier assignment
- **Impact**: Reduced confusion about backup expectations, easier onboarding of new systems
- **Timeline**: Immediate and ongoing

#### 5. Disaster Recovery Alignment
- **Benefit**: Backup strategy aligns with actual recovery requirements
- **Impact**: Faster recovery of critical systems, appropriate recovery time for non-critical systems
- **Timeline**: Immediate and ongoing

#### 6. Scalability
- **Benefit**: Easy to add new VMs with appropriate tier assignment
- **Impact**: Infrastructure can grow without proportional increase in backup complexity
- **Timeline**: Immediate and ongoing

#### 7. Monitoring and Alerting
- **Benefit**: Clear backup job definitions enable better monitoring
- **Impact**: Faster detection and resolution of backup failures
- **Timeline**: Immediate and ongoing

#### 8. Storage Optimization
- **Benefit**: Different storage tiers for different backup frequencies
- **Impact**: Efficient use of storage resources, potential cost savings
- **Timeline**: Immediate and ongoing

### Negative

#### 1. Increased Complexity
- **Drawback**: Multiple pools and schedules to manage
- **Impact**: More backup jobs to configure and monitor
- **Mitigation**: Automate tier assignment through module variables; use consistent naming conventions; implement monitoring dashboard

#### 2. Storage Overhead
- **Drawback**: Multiple pools may require more storage initially
- **Impact**: Higher initial storage capacity needed
- **Mitigation**: Plan storage capacity for all tiers; use compression; implement cleanup policies

#### 3. Operational Burden
- **Drawback**: More backup jobs to monitor and maintain
- **Impact**: More operational work required
- **Mitigation**: Implement automated monitoring; create runbooks for common tasks; document tier assignment

#### 4. Tier Assignment Decisions
- **Drawback**: Requires careful decision about which tier each VM belongs to
- **Impact**: Incorrect tier assignment could result in inadequate protection or over-investment
- **Mitigation**: Document tier assignment criteria; review assignments regularly; provide clear guidelines

#### 5. Migration Complexity
- **Drawback**: Moving VMs between tiers requires backup reconfiguration
- **Impact**: Operational effort to change tier assignments
- **Mitigation**: Create runbooks for tier migration; plan tier changes carefully; test in sandbox

#### 6. Retention Policy Enforcement
- **Drawback**: Different retention policies must be enforced consistently
- **Impact**: Risk of accidental deletion of backups or retention violations
- **Mitigation**: Implement automated retention policies; monitor retention compliance; document policies

### Risks and Mitigation

#### Risk 1: Incorrect Tier Assignment
**Risk**: VMs assigned to wrong tier (e.g., critical data in Tier 2)
**Probability**: Medium
**Impact**: Inadequate protection of critical data or over-investment in non-critical data
**Mitigation**:
- Document tier assignment criteria clearly
- Review tier assignments quarterly
- Implement tier assignment validation in code
- Provide clear guidelines for tier selection
- Test recovery procedures for each tier

#### Risk 2: Backup Job Failures
**Risk**: Backup jobs fail silently without detection
**Probability**: Medium
**Impact**: Data not backed up, undetected until recovery needed
**Mitigation**:
- Implement monitoring and alerting for backup jobs
- Create dashboard for backup status
- Test backup jobs regularly
- Document troubleshooting procedures
- Implement automated retry logic

#### Risk 3: Storage Capacity Issues
**Risk**: Backup storage fills up unexpectedly
**Probability**: Medium
**Impact**: Backup jobs fail due to insufficient storage
**Mitigation**:
- Monitor storage usage for each tier
- Implement storage quotas
- Plan capacity growth
- Implement cleanup policies
- Alert when storage reaches threshold

#### Risk 4: Recovery Procedure Failures
**Risk**: Recovery procedures don't work as expected
**Probability**: Medium
**Impact**: Unable to recover data when needed
**Mitigation**:
- Test recovery procedures regularly (monthly)
- Document recovery procedures for each tier
- Create runbooks for common recovery scenarios
- Maintain recovery procedure documentation
- Practice disaster recovery drills

#### Risk 5: Retention Policy Violations
**Risk**: Backups deleted before retention period expires
**Probability**: Low
**Impact**: Data loss, compliance violations
**Mitigation**:
- Implement automated retention policies
- Monitor retention compliance
- Document retention policies
- Implement backup locks if available
- Regular audits of retention compliance

#### Risk 6: Tier Migration Complexity
**Risk**: Changing tier assignments causes backup disruption
**Probability**: Low
**Impact**: Backup gaps during tier migration
**Mitigation**:
- Create runbooks for tier migration
- Plan tier changes carefully
- Test in sandbox environment first
- Maintain backups during migration
- Communicate changes to stakeholders

## Alternatives Considered

### Alternative 1: Single Backup Pool (Current Approach)
**Pros:**
- Simple to understand and implement
- Single backup schedule for all VMs
- Minimal operational complexity
- Easier to monitor (fewer jobs)
- Consistent backup frequency

**Cons:**
- Inefficient resource allocation
- Over-invests in non-critical data
- May under-protect critical data
- Higher storage costs
- Doesn't align with actual recovery requirements
- Difficult to scale to many VMs
- No compliance differentiation

**Why Rejected**: Single pool approach is inefficient and doesn't align with business requirements. Tiered approach provides better protection at lower cost.

### Alternative 2: Cloud-Based Backup Tiers
**Pros:**
- Managed by cloud provider
- Automatic scaling
- High availability built-in
- No on-premises infrastructure needed
- Excellent support

**Cons:**
- Requires cloud provider (AWS, Azure, GCP)
- Vendor lock-in
- Not suitable for on-premises Proxmox
- Higher cost for frequent backups
- Less control over backup strategy
- Compliance concerns with cloud storage
- Network bandwidth costs

**Why Rejected**: Incompatible with on-premises Proxmox infrastructure. Would require complete rewrite for different platform. Higher costs for frequent backups.

### Alternative 3: Manual Backup Management
**Pros:**
- No additional infrastructure needed
- Complete control over backup process
- Can customize for specific needs
- No automation overhead

**Cons:**
- Error-prone and unreliable
- Difficult to scale
- No audit trail
- Difficult to enforce retention policies
- High operational burden
- Difficult to test recovery procedures
- Not suitable for production

**Why Rejected**: Manual management is unreliable and not scalable. Unacceptable for production workloads. Automation is essential for reliable backups.

### Alternative 4: Time-Based Retention Only
**Pros:**
- Simple to understand
- Easy to implement
- Minimal configuration
- Works with any backup tool

**Cons:**
- Doesn't differentiate by data criticality
- May not meet compliance requirements
- Inefficient resource allocation
- Difficult to optimize storage
- No alignment with recovery requirements
- Difficult to scale

**Why Rejected**: Time-based retention alone doesn't address the core problem of differentiating backup strategies by data criticality. Tiered approach provides better alignment with business requirements.

### Alternative 5: Backup Frequency Based on Data Size
**Pros:**
- Objective criteria for tier assignment
- Easy to automate
- Scales with data growth

**Cons:**
- Doesn't consider data criticality
- Large non-critical data gets frequent backups
- Small critical data might get infrequent backups
- Doesn't align with recovery requirements
- Difficult to change tier assignments

**Why Rejected**: Data size is not a good indicator of criticality. A small database might be more critical than a large cache. Criticality-based tiering is more appropriate.

### Alternative 6: Backup Frequency Based on Change Rate
**Pros:**
- Adapts to actual data change patterns
- Efficient resource allocation
- Automatic tier assignment possible

**Cons:**
- Requires monitoring change rates
- Difficult to predict backup needs
- May change tier assignments frequently
- Doesn't consider criticality
- Complex to implement

**Why Rejected**: While change rate is relevant, it doesn't capture the full picture. Criticality is more important than change rate for backup strategy.

## Comparison Matrix

| Criteria                     | Tiered Strategy | Single Pool | Cloud Backup | Manual    | Time-Based |
| ---------------------------- | --------------- | ----------- | ------------ | --------- | ---------- |
| **Cost Efficiency**          | ✅ Excellent     | ⚠️ Medium    | ❌ High       | ✅ Low     | ⚠️ Medium   |
| **Operational Complexity**   | ⚠️ Medium        | ✅ Low       | ✅ Low        | ❌ High    | ✅ Low      |
| **Compliance Support**       | ✅ Yes           | ⚠️ Partial   | ⚠️ Partial    | ❌ No      | ⚠️ Partial  |
| **Scalability**              | ✅ Excellent     | ⚠️ Limited   | ✅ Excellent  | ❌ Poor    | ⚠️ Limited  |
| **Data Protection**          | ✅ Optimized     | ⚠️ Uniform   | ✅ Good       | ❌ Poor    | ⚠️ Uniform  |
| **Recovery Time (Critical)** | ✅ 4 hours       | ⚠️ 24 hours  | ⚠️ 24+ hours  | ❌ Unknown | ⚠️ 24 hours |
| **Automation**               | ✅ Yes           | ✅ Yes       | ✅ Yes        | ❌ No      | ✅ Yes      |
| **On-Premises Support**      | ✅ Yes           | ✅ Yes       | ❌ No         | ✅ Yes     | ✅ Yes      |
| **Monitoring**               | ✅ Good          | ⚠️ Medium    | ✅ Good       | ❌ Poor    | ⚠️ Medium   |
| **Disaster Recovery Ready**  | ✅ Yes           | ⚠️ Partial   | ⚠️ Partial    | ❌ No      | ⚠️ Partial  |
| **Vendor Lock-in**           | ✅ None          | ✅ None      | ❌ High       | ✅ None    | ✅ None     |
| **Compliance Alignment**     | ✅ Excellent     | ⚠️ Limited   | ⚠️ Limited    | ❌ Poor    | ⚠️ Limited  |

## Implementation Details

### OpenTofu Changes
1. Create backup pool resources for each tier in `proxmox/backup.tf`
2. Add `backup_tier` variable to `data_disk_vm` module
3. Update VM configurations to specify backup tier
4. Create backup job definitions (future: integrate with PBS)
5. Implement monitoring and alerting for backup jobs

### Module Enhancement
The `data_disk_vm` module will accept:
```hcl
backup_tier = 1  # or 2, 3, 4 (numeric tier ID)
```

### Pool Naming Convention
```
tier-1  (Critical Production)
tier-2  (Standard Application)
tier-3  (Development/Testing)
tier-4  (Cache/Temporary)
```

### VM Tier Assignment
- **Postgres**: Tier 1 (production database)
- **PBS**: Tier 1 (backup infrastructure)
- **Ollama**: Tier 4 (regenerable models)
- **Sandbox**: Tier 3 (development environment)
- **New VMs**: Explicitly assigned based on purpose

### Backup Job Configuration
Each tier will have:
- Scheduled backup job with appropriate frequency
- Retention policy matching tier requirements
- Monitoring and alerting
- Verification and integrity checks
- Documentation of backup procedures

### Monitoring and Alerting
- Dashboard showing backup status for each tier
- Alerts for failed backup jobs
- Alerts for storage capacity issues
- Alerts for retention policy violations
- Regular backup verification reports

## Future Enhancements

1. **PBS Integration**: Integrate with Proxmox Backup Server for automated backup scheduling
2. **Backup Dashboard**: Create comprehensive backup monitoring dashboard
3. **Automated Tier Migration**: Implement automated tier migration based on age or criticality changes
4. **Backup Verification**: Add automated backup verification and integrity checks
5. **Recovery Testing**: Implement automated recovery testing for each tier
6. **Backup Deduplication**: Implement deduplication across backup pools
7. **Incremental Backups**: Implement incremental backups for Tier 1 to reduce storage
8. **Backup Encryption**: Implement encryption for backups at rest
9. **Offsite Backups**: Implement offsite backup replication for disaster recovery
10. **Backup Reporting**: Create automated backup reports for compliance

## References

### Backup and Disaster Recovery Documentation
- [Proxmox Backup Server Documentation](https://pbs.proxmox.com/docs/index.html)
- [Proxmox VE Backup Guide](https://pve.proxmox.com/wiki/Backup_and_Restore)
- [OpenTofu Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

### Industry Best Practices
- [NIST Backup and Recovery Guidelines](https://csrc.nist.gov/publications/detail/sp/800-34/rev-1/final)
- [Veeam Backup Best Practices](https://www.veeam.com/blog/backup-best-practices.html)
- [Disaster Recovery Planning Guide](https://www.ready.gov/business/implementation/recovery)

### Backup Strategy References
- [RPO/RTO Definition and Planning](https://www.vmware.com/topics/glossary/content/recovery-point-objective-rpo)
- [Tiered Backup Strategy](https://www.backblaze.com/blog/backup-strategy-3-2-1-rule/)
- [Data Retention Policies](https://www.ibm.com/cloud/learn/data-retention)

### Related ADRs
- [ADR-001: Platform Choice (OpenTofu vs Terraform)](./ADR-001-platform-choice-opentofu-vs-terraform.md)
- [ADR-002: Kubernetes Approach (Talos Linux)](./ADR-002-kubernetes-approach-talos-linux.md)
- [ADR-003: Storage Strategy (Longhorn)](./ADR-003-storage-strategy-longhorn.md)
- [ADR-004: Security Model (Vault + RBAC)](./ADR-004-security-model-vault-rbac.md)

---

## Decision Metadata

**Decision Date**: November 2025  
**Last Updated**: November 7, 2025  
**Status**: Accepted and Implemented  
**Decision Owner**: Infrastructure Team  