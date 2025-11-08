# ADR-002: Kubernetes Approach (Talos Linux)

## Status
**Accepted**

## Context

### Problem Statement
The homelab infrastructure requires a Kubernetes distribution to orchestrate containerized applications. The choice of Kubernetes distribution is critical because it affects:

- Security posture and attack surface
- Operational complexity and maintenance burden
- Scalability and performance characteristics
- Compliance and auditability requirements
- Integration with Infrastructure-as-Code tools
- Long-term supportability and upgrade paths

### Constraints and Assumptions

**Constraints:**
- Must run on Proxmox VE virtual machines
- Must support immutable infrastructure principles
- Must be manageable via Infrastructure-as-Code (OpenTofu)
- Must support distributed storage (Longhorn)
- Must support advanced networking (Cilium)
- Must have minimal attack surface
- Must be suitable for homelab scale (2-6 nodes)

**Assumptions:**
- Security is more important than operational simplicity
- Immutable infrastructure is a core design principle
- API-driven configuration is preferred over manual setup
- The infrastructure will evolve and scale over time
- Compliance and auditability are important

### Requirements That Influenced the Decision

1. **Immutable Infrastructure**: OS should be immutable and API-driven
2. **Minimal Attack Surface**: Reduce CVE exposure and security risks
3. **API-First Design**: All configuration via API, not manual steps
4. **Declarative Configuration**: Version-controlled, reproducible setup
5. **Security by Default**: No SSH, no shell, no package manager
6. **Kubernetes Native**: Designed specifically for Kubernetes
7. **Scalability**: Support for cluster growth from 1 to many nodes
8. **Operational Excellence**: Automated updates and maintenance

## Decision

**Chosen: Talos Linux**

Talos Linux was selected as the Kubernetes distribution for this homelab infrastructure.

### Key Factors That Led to This Choice

#### 1. Immutable Operating System Design
- **Talos Linux**: Fully immutable OS
  - No SSH access
  - No shell access
  - No package manager
  - No manual modifications possible
  - All configuration via API
  
- **kubeadm/Ubuntu**: Mutable OS
  - SSH access available
  - Package manager available
  - Manual modifications possible
  - Configuration via files and commands
  - Drift possible

**Impact**: Talos eliminates entire classes of security vulnerabilities and configuration drift.

#### 2. Minimal Attack Surface
- **Talos Linux**:
  - Only Kubernetes essentials included
  - No unnecessary services
  - No SSH daemon
  - No shell interpreter
  - Reduced CVE exposure
  - Faster security patches
  
- **Ubuntu/Debian**:
  - Full Linux distribution
  - Many unnecessary services
  - SSH daemon running
  - Shell access available
  - Larger CVE surface
  - More patches needed

**Impact**: Talos significantly reduces security risk and maintenance burden.

#### 3. API-Driven Configuration
- **Talos Linux**:
  - All configuration via Talos API
  - YAML-based machine configuration
  - Version-controlled configuration
  - Reproducible deployments
  - Perfect for Infrastructure-as-Code
  
- **kubeadm**:
  - Manual configuration steps
  - Configuration files scattered across system
  - Difficult to version control
  - Hard to reproduce exactly
  - Not ideal for IaC

**Impact**: Talos enables true Infrastructure-as-Code for the OS layer.

#### 4. Kubernetes-Native Design
- **Talos Linux**:
  - Designed specifically for Kubernetes
  - Optimized for container workloads
  - Minimal resource overhead
  - Perfect integration with Kubernetes
  - No unnecessary OS features
  
- **Ubuntu/Debian**:
  - General-purpose Linux distribution
  - Many features not needed for Kubernetes
  - Larger resource footprint
  - More complexity to manage

**Impact**: Talos provides better performance and simpler operations.

#### 5. Secure by Default
- **Talos Linux**:
  - No default SSH keys
  - No shell access
  - Encrypted communication
  - RBAC enforced
  - Audit logging built-in
  
- **Ubuntu/Debian**:
  - SSH access by default
  - Shell access available
  - Requires manual hardening
  - Security is optional
  - Audit logging requires setup

**Impact**: Talos provides security without additional configuration.

#### 6. Declarative and Reproducible
- **Talos Linux**:
  - Single source of truth (machine config)
  - Reproducible deployments
  - Easy to version control
  - Easy to test changes
  - Easy to rollback
  
- **kubeadm**:
  - Multiple configuration sources
  - Manual steps required
  - Hard to reproduce exactly
  - Difficult to version control
  - Difficult to rollback

**Impact**: Talos enables reliable, repeatable infrastructure.

#### 7. Operational Excellence
- **Talos Linux**:
  - Automated updates
  - No manual patching
  - Atomic updates
  - Automatic rollback on failure
  - Minimal downtime
  
- **Ubuntu/Debian**:
  - Manual update management
  - Requires downtime
  - Risk of breaking changes
  - Manual rollback needed
  - More operational burden

**Impact**: Talos reduces operational overhead and improves reliability.

## Consequences

### Positive

#### 1. Enhanced Security
- **Benefit**: Immutable OS eliminates entire classes of vulnerabilities
- **Impact**: Reduced security risk and compliance burden
- **Timeline**: Immediate and ongoing

#### 2. Reduced Attack Surface
- **Benefit**: No SSH, no shell, no package manager
- **Impact**: Fewer CVEs to patch, faster security updates
- **Timeline**: Immediate and ongoing

#### 3. Operational Simplicity
- **Benefit**: API-driven configuration, automated updates
- **Impact**: Less manual work, fewer operational errors
- **Timeline**: Immediate and ongoing

#### 4. Reproducibility
- **Benefit**: Declarative configuration, version-controlled
- **Impact**: Easy to recreate environments, easy to test changes
- **Timeline**: Immediate and ongoing

#### 5. Compliance and Auditability
- **Benefit**: All changes tracked in Git, audit logging built-in
- **Impact**: Better compliance posture, easier audits
- **Timeline**: Immediate and ongoing

#### 6. Performance
- **Benefit**: Minimal OS overhead, optimized for Kubernetes
- **Impact**: Better resource utilization, better performance
- **Timeline**: Immediate and ongoing

#### 7. Scalability
- **Benefit**: Easy to add new nodes, consistent configuration
- **Impact**: Simple cluster growth, no configuration drift
- **Timeline**: Immediate and ongoing

### Negative

#### 1. Learning Curve
- **Drawback**: Different from traditional Linux
- **Impact**: Requires learning new tools and concepts
- **Mitigation**: Comprehensive documentation available; community growing

#### 2. Limited Debugging Capabilities
- **Drawback**: No shell access for troubleshooting
- **Impact**: Debugging requires different approaches
- **Mitigation**: Talos provides debugging tools; logs are comprehensive

#### 3. Smaller Community
- **Drawback**: Fewer users and resources than Ubuntu/Debian
- **Impact**: Fewer Stack Overflow answers, fewer tutorials
- **Mitigation**: Community is growing; documentation is excellent

#### 4. Talos-Specific Tools Required
- **Drawback**: Must use talosctl instead of standard Linux tools
- **Impact**: Different workflow for operations
- **Mitigation**: talosctl is well-designed and documented

#### 5. Limited Customization
- **Drawback**: Cannot install arbitrary packages
- **Impact**: Must use container-based solutions for additional tools
- **Mitigation**: Container-based approach is actually better practice

#### 6. Vendor Lock-in Risk
- **Drawback**: Talos is specific to Kubernetes
- **Impact**: Cannot use OS for non-Kubernetes workloads
- **Mitigation**: Talos is open-source; can be forked if needed

### Risks and Mitigation

#### Risk 1: Community Adoption
**Risk**: Talos may not achieve widespread adoption
**Probability**: Low
**Impact**: Reduced ecosystem support and third-party tools
**Mitigation**:
- Monitor community growth and adoption
- Contribute to Talos project
- Maintain documentation for common tasks
- Build internal expertise

#### Risk 2: Debugging Complexity
**Risk**: Lack of shell access may complicate troubleshooting
**Probability**: Medium
**Impact**: Longer mean-time-to-resolution for issues
**Mitigation**:
- Learn talosctl debugging tools
- Implement comprehensive logging
- Use Kubernetes-native debugging tools
- Document common issues and solutions

#### Risk 3: Feature Limitations
**Risk**: Immutability may prevent needed customizations
**Probability**: Low
**Impact**: May need to use containers for additional functionality
**Mitigation**:
- Plan for container-based solutions
- Use Kubernetes extensions (operators, controllers)
- Contribute features to Talos if needed

#### Risk 4: Upgrade Complexity
**Risk**: OS upgrades may have unexpected issues
**Probability**: Low
**Impact**: Cluster downtime or data loss
**Mitigation**:
- Test upgrades in sandbox environment first
- Maintain backups before upgrades
- Use staged rollout for upgrades
- Monitor upgrade process carefully

#### Risk 5: Tool Ecosystem
**Risk**: Fewer third-party tools support Talos
**Probability**: Medium
**Impact**: May need custom solutions for some tasks
**Mitigation**:
- Use Kubernetes-native tools when possible
- Build custom solutions as needed
- Contribute tools back to community

## Alternatives Considered

### Alternative 1: kubeadm on Ubuntu/Debian
**Pros:**
- Large community and ecosystem
- Familiar to most Linux users
- Flexible and customizable
- More third-party tools available
- Easier debugging with shell access

**Cons:**
- Mutable OS allows configuration drift
- Larger attack surface
- More manual configuration required
- Harder to reproduce exactly
- More operational burden
- Not designed for Kubernetes

**Why Rejected**: Mutable OS violates immutable infrastructure principles. Larger attack surface and operational complexity outweigh ecosystem advantages.

### Alternative 2: k3s (Lightweight Kubernetes)
**Pros:**
- Lightweight and minimal
- Easy to install and manage
- Good for edge and IoT
- Single binary distribution
- Good documentation

**Cons:**
- Still runs on mutable OS (Ubuntu/Debian)
- Less suitable for production
- Smaller community than kubeadm
- Less flexible than full Kubernetes
- Not designed for immutable infrastructure

**Why Rejected**: While lightweight, k3s still requires mutable OS. Doesn't provide security benefits of Talos. Better suited for edge computing than homelab.

### Alternative 3: Managed Kubernetes (EKS, AKS, GKE)
**Pros:**
- Fully managed by cloud provider
- No operational burden
- Automatic updates and patches
- High availability built-in
- Excellent support

**Cons:**
- Requires cloud provider (AWS, Azure, GCP)
- Vendor lock-in
- Not suitable for on-premises Proxmox
- Higher cost
- Less control over infrastructure
- Defeats purpose of homelab

**Why Rejected**: Incompatible with on-premises Proxmox infrastructure. Would require complete rewrite for different platform.

### Alternative 4: RKE2 (Rancher Kubernetes Engine)
**Pros:**
- Production-grade Kubernetes
- Good security defaults
- Easy to install
- Good documentation
- Rancher ecosystem

**Cons:**
- Still runs on mutable OS
- More complex than Talos
- Larger resource footprint
- Not designed for immutable infrastructure
- Vendor-influenced (Rancher/SUSE)

**Why Rejected**: While good, RKE2 still uses mutable OS. Doesn't provide immutability benefits of Talos. More complex without additional benefits.

### Alternative 5: Flatcar Container Linux
**Pros:**
- Immutable OS
- Minimal design
- Good for containers
- Community-driven

**Cons:**
- Not Kubernetes-specific
- Requires manual Kubernetes setup
- Smaller community than Talos
- Less integrated with Kubernetes
- More operational complexity

**Why Rejected**: While immutable, Flatcar is not Kubernetes-specific. Requires more manual setup than Talos. Talos is better integrated with Kubernetes.

## Comparison Matrix

| Criteria                | Talos     | kubeadm | k3s       | RKE2      | Managed K8s |
| ----------------------- | --------- | ------- | --------- | --------- | ----------- |
| **Immutable OS**        | ✅ Yes     | ❌ No    | ❌ No      | ❌ No      | ✅ Yes       |
| **API-Driven**          | ✅ Yes     | ❌ No    | ❌ No      | ⚠️ Partial | ✅ Yes       |
| **Minimal Design**      | ✅ Yes     | ❌ No    | ✅ Yes     | ⚠️ Medium  | ✅ Yes       |
| **Security by Default** | ✅ Yes     | ❌ No    | ⚠️ Partial | ⚠️ Partial | ✅ Yes       |
| **On-Premises**         | ✅ Yes     | ✅ Yes   | ✅ Yes     | ✅ Yes     | ❌ No        |
| **Community Size**      | ⚠️ Growing | ✅ Large | ✅ Large   | ⚠️ Medium  | ✅ Large     |
| **Learning Curve**      | ❌ Steep   | ✅ Easy  | ✅ Easy    | ⚠️ Medium  | ✅ Easy      |
| **Debugging**           | ⚠️ Limited | ✅ Easy  | ✅ Easy    | ✅ Easy    | ✅ Easy      |
| **Customization**       | ⚠️ Limited | ✅ High  | ✅ High    | ✅ High    | ❌ Limited   |
| **Operational Burden**  | ✅ Low     | ❌ High  | ⚠️ Medium  | ⚠️ Medium  | ✅ Low       |

## References

### Talos Linux Documentation
- [Talos Linux Official Documentation](https://www.talos.dev/)
- [Talos Linux GitHub Repository](https://github.com/siderolabs/talos)
- [Talos Linux Architecture](https://www.talos.dev/latest/learn-more/architecture/)

### Kubernetes Documentation
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)

### Industry References
- [Immutable Infrastructure Patterns](https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Container Security](https://www.cisecurity.org/cis-benchmarks/)

---

**Decision Date**: November 2025  
**Last Updated**: November 6, 2025  
**Status**: Accepted and Implemented  
**Related Components**: Kubernetes cluster in `tofu/infrastructure/vms/kubernetes/`
