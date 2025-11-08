# ADR-004: Security Model (Vault + RBAC)

## Status
**Accepted**

## Context

### Problem Statement
The homelab infrastructure requires a comprehensive security model to protect sensitive data and control access to resources. The choice of secrets management and access control strategy is critical because it affects:

- Confidentiality of sensitive data (passwords, API keys, certificates)
- Integrity of configuration and access controls
- Availability of services during security incidents
- Compliance with security standards and regulations
- Operational complexity and maintenance burden
- Auditability and forensic capabilities
- Scalability and performance of security systems

### Constraints and Assumptions

**Constraints:**
- Must protect secrets (database passwords, API keys, certificates)
- Must support Kubernetes RBAC for access control
- Must integrate with Kubernetes authentication
- Must support audit logging for compliance
- Must be suitable for homelab scale
- Must support automated secret injection
- Must support secret rotation
- Must be open-source and self-hosted

**Assumptions:**
- Secrets should never be stored in Git or configuration files
- Principle of least privilege should be enforced
- All access should be auditable
- Secrets should be encrypted at-rest and in-transit
- Service accounts should have minimal required permissions
- Network policies should restrict access

### Requirements That Influenced the Decision

1. **Centralized Secrets Management**: Single source of truth for secrets
2. **Encryption**: Secrets encrypted at-rest and in-transit
3. **Audit Logging**: Full audit trail of secret access
4. **Access Control**: Fine-grained RBAC for secret access
5. **Automation**: Automatic secret injection into pods
6. **Rotation**: Support for secret rotation
7. **Compliance**: Support for compliance requirements
8. **Scalability**: Support for growth from homelab to enterprise

## Decision

**Chosen: HashiCorp Vault + Kubernetes RBAC**

HashiCorp Vault combined with Kubernetes RBAC was selected as the security model for this homelab infrastructure.

### Key Factors That Led to This Choice

#### 1. Centralized Secrets Management
- **Vault**:
  - Single source of truth for all secrets
  - Centralized management and rotation
  - Audit logging of all access
  - Encryption at-rest and in-transit
  - Support for multiple secret engines
  
- **Kubernetes Secrets**:
  - Distributed across etcd
  - No centralized management
  - Limited audit logging
  - Encryption at-rest only (optional)
  - No secret rotation support
  
- **Environment Variables**:
  - Scattered across deployments
  - No centralized management
  - Difficult to rotate
  - No audit logging
  - Security risk

**Impact**: Vault provides centralized, auditable secrets management.

#### 2. Encryption and Protection
- **Vault**:
  - Encryption at-rest (AES-256)
  - Encryption in-transit (TLS)
  - Automatic key rotation
  - Secure key storage
  - Encryption key separation
  
- **Kubernetes Secrets**:
  - Base64 encoding (not encryption)
  - Optional encryption at-rest
  - No in-transit encryption
  - Keys stored in etcd
  - No key rotation
  
- **Plain Text**:
  - No encryption
  - Visible in logs
  - Visible in configuration
  - Security risk

**Impact**: Vault provides strong encryption and key management.

#### 3. Audit Logging and Compliance
- **Vault**:
  - Comprehensive audit logging
  - All access logged
  - Compliance-ready
  - Forensic capabilities
  - Retention policies
  
- **Kubernetes RBAC**:
  - API server audit logging
  - Limited to API access
  - No secret access logging
  - Requires additional tools
  
- **No Audit Logging**:
  - No compliance trail
  - Difficult to investigate incidents
  - Security risk

**Impact**: Vault provides compliance-ready audit logging.

#### 4. Kubernetes RBAC Integration
- **Kubernetes RBAC**:
  - Fine-grained access control
  - Role-based permissions
  - Service account binding
  - Namespace isolation
  - Network policies
  
- **No RBAC**:
  - All users have same permissions
  - No access control
  - Security risk
  
- **External RBAC**:
  - Difficult to integrate
  - Operational complexity

**Impact**: Kubernetes RBAC provides fine-grained access control.

#### 5. Automatic Secret Injection
- **Vault Agent**:
  - Automatic secret injection into pods
  - Init container approach
  - Transparent to applications
  - No code changes needed
  - Secure secret handling
  
- **Manual Secret Management**:
  - Developers must handle secrets
  - Error-prone
  - Security risk
  - Code changes needed
  
- **Environment Variables**:
  - Visible in pod spec
  - Visible in logs
  - Security risk

**Impact**: Vault Agent provides automatic, secure secret injection.

#### 6. Secret Rotation Support
- **Vault**:
  - Built-in secret rotation
  - Automatic rotation policies
  - Zero-downtime rotation
  - Audit trail of rotations
  
- **Kubernetes Secrets**:
  - Manual rotation required
  - Requires pod restart
  - Downtime needed
  - No automation
  
- **Manual Management**:
  - Error-prone
  - Difficult to track
  - Security risk

**Impact**: Vault enables automated secret rotation.

#### 7. Multiple Secret Engines
- **Vault**:
  - KV v2 for application secrets
  - Database engine for dynamic credentials
  - PKI engine for certificates
  - SSH engine for SSH keys
  - AWS/Azure engines for cloud credentials
  
- **Kubernetes Secrets**:
  - Only static secrets
  - No dynamic credentials
  - No certificate management
  
- **External Tools**:
  - Multiple tools needed
  - Operational complexity
  - Integration challenges

**Impact**: Vault provides multiple secret engines for different use cases.

#### 8. Community and Ecosystem
- **Vault**:
  - Mature, battle-tested project
  - Large community
  - Excellent documentation
  - Enterprise support available
  - HashiCorp backing
  
- **Kubernetes Secrets**:
  - Part of Kubernetes
  - Large community
  - Limited functionality
  
- **External Solutions**:
  - Smaller communities
  - Less mature
  - Less documentation

**Impact**: Vault has strong community support and maturity.

## Consequences

### Positive

#### 1. Centralized Secrets Management
- **Benefit**: Single source of truth for all secrets
- **Impact**: Easier to manage and audit
- **Timeline**: Immediate and ongoing

#### 2. Strong Encryption
- **Benefit**: AES-256 encryption at-rest and in-transit
- **Impact**: Protection against data breaches
- **Timeline**: Immediate and ongoing

#### 3. Audit Logging
- **Benefit**: Comprehensive audit trail of all access
- **Impact**: Compliance and forensic capabilities
- **Timeline**: Immediate and ongoing

#### 4. Automatic Secret Injection
- **Benefit**: Transparent secret injection into pods
- **Impact**: Reduced developer burden
- **Timeline**: Immediate and ongoing

#### 5. Secret Rotation
- **Benefit**: Automated secret rotation
- **Impact**: Reduced security risk
- **Timeline**: Immediate and ongoing

#### 6. Fine-Grained Access Control
- **Benefit**: RBAC for secret access
- **Impact**: Principle of least privilege
- **Timeline**: Immediate and ongoing

#### 7. Compliance Ready
- **Benefit**: Audit logging and encryption for compliance
- **Impact**: Easier compliance audits
- **Timeline**: Immediate and ongoing

#### 8. Scalability
- **Benefit**: Scales from homelab to enterprise
- **Impact**: Future-proof security model
- **Timeline**: Immediate and ongoing

### Negative

#### 1. Operational Complexity
- **Drawback**: Vault adds operational complexity
- **Impact**: More components to manage
- **Mitigation**: Comprehensive documentation; automated deployment

#### 2. Learning Curve
- **Drawback**: Vault has steep learning curve
- **Impact**: Time needed to understand and operate
- **Mitigation**: Excellent documentation; community support

#### 3. Additional Infrastructure
- **Drawback**: Vault requires separate infrastructure
- **Impact**: Additional VM or pod needed
- **Mitigation**: Lightweight deployment; can run in Kubernetes

#### 4. Dependency on Vault
- **Drawback**: Applications depend on Vault availability
- **Impact**: Vault outage affects all applications
- **Mitigation**: High availability setup; monitoring

#### 5. Secret Injection Complexity
- **Drawback**: Secret injection adds pod startup complexity
- **Impact**: Slightly longer pod startup time
- **Mitigation**: Minimal impact; acceptable for homelab

#### 6. RBAC Complexity
- **Drawback**: RBAC requires careful configuration
- **Impact**: Misconfiguration can cause access issues
- **Mitigation**: Clear documentation; testing in sandbox

### Risks and Mitigation

#### Risk 1: Vault Compromise
**Risk**: Vault itself could be compromised
**Probability**: Low
**Impact**: All secrets exposed
**Mitigation**:
- Secure Vault infrastructure
- Use strong authentication
- Enable audit logging
- Regular security audits
- Implement network policies
- Use TLS for all communication

#### Risk 2: Vault Unavailability
**Risk**: Vault outage prevents secret access
**Probability**: Low
**Impact**: Applications unable to start
**Mitigation**:
- High availability setup
- Monitoring and alerting
- Backup and recovery procedures
- Graceful degradation
- Caching of secrets

#### Risk 3: Secret Leakage
**Risk**: Secrets leaked through logs or errors
**Probability**: Medium
**Impact**: Secrets exposed
**Mitigation**:
- Audit logging
- Log redaction
- Error handling
- Code review
- Security testing

#### Risk 4: RBAC Misconfiguration
**Risk**: Incorrect RBAC allows unauthorized access
**Probability**: Medium
**Impact**: Unauthorized secret access
**Mitigation**:
- Principle of least privilege
- Regular RBAC audits
- Testing in sandbox
- Clear documentation
- Code review

#### Risk 5: Secret Rotation Issues
**Risk**: Secret rotation fails or causes downtime
**Probability**: Low
**Impact**: Service disruption
**Mitigation**:
- Test rotation procedures
- Gradual rollout
- Monitoring during rotation
- Rollback procedures
- Communication plan

## Alternatives Considered

### Alternative 1: Kubernetes Secrets Only
**Pros:**
- Built-in to Kubernetes
- No additional infrastructure
- Simple to understand
- No learning curve

**Cons:**
- No centralized management
- Base64 encoding (not encryption)
- No audit logging
- No secret rotation
- No access control
- Secrets visible in etcd
- Not suitable for production

**Why Rejected**: Kubernetes Secrets lack essential security features. Base64 encoding is not encryption. No audit logging or access control.

### Alternative 2: External Secrets Operator (ESO)
**Pros:**
- Kubernetes-native approach
- Works with multiple backends
- Good integration with Vault
- Reduces operational complexity

**Cons:**
- Still requires Vault or similar backend
- Additional complexity
- Requires ESO operator
- Not a complete solution

**Why Rejected**: ESO is a good complement to Vault but not a replacement. Still requires Vault for actual secret storage.

### Alternative 3: AWS Secrets Manager / Azure Key Vault
**Pros:**
- Managed by cloud provider
- High availability built-in
- Excellent support
- Integrated with cloud services

**Cons:**
- Requires cloud provider
- Vendor lock-in
- Not suitable for on-premises
- Higher cost
- Less control

**Why Rejected**: Incompatible with on-premises Proxmox infrastructure. Would require complete rewrite for different platform.

### Alternative 4: Sealed Secrets
**Pros:**
- Kubernetes-native
- Secrets stored in Git (encrypted)
- Simple to understand
- Good for GitOps

**Cons:**
- Limited functionality
- No centralized management
- No audit logging
- No secret rotation
- No access control
- Encryption key in cluster

**Why Rejected**: Sealed Secrets are good for GitOps but lack centralized management and audit logging. Better used with Vault.

### Alternative 5: Manual Secret Management
**Pros:**
- No additional tools
- Simple to understand
- No learning curve

**Cons:**
- Error-prone
- No audit logging
- No encryption
- No access control
- Difficult to rotate
- Security risk
- Not scalable

**Why Rejected**: Manual management is insecure and not scalable. Unacceptable for production workloads.

### Alternative 6: HashiCorp Consul
**Pros:**
- Service mesh capabilities
- Configuration management
- Health checking
- Service discovery

**Cons:**
- More complex than Vault
- Overkill for secrets management
- Requires more infrastructure
- Steeper learning curve

**Why Rejected**: Consul is more complex than needed. Vault is better focused on secrets management.

## Comparison Matrix

| Criteria             | Vault + RBAC | K8s Secrets | ESO       | Sealed Secrets | Manual |
| -------------------- | ------------ | ----------- | --------- | -------------- | ------ |
| **Centralized**      | ✅ Yes        | ❌ No        | ⚠️ Partial | ❌ No           | ❌ No   |
| **Encryption**       | ✅ AES-256    | ⚠️ Optional  | ✅ Yes     | ✅ Yes          | ❌ No   |
| **Audit Logging**    | ✅ Yes        | ❌ No        | ❌ No      | ❌ No           | ❌ No   |
| **Access Control**   | ✅ Yes        | ⚠️ Limited   | ⚠️ Limited | ❌ No           | ❌ No   |
| **Secret Rotation**  | ✅ Yes        | ❌ No        | ❌ No      | ❌ No           | ❌ No   |
| **Automation**       | ✅ Yes        | ❌ No        | ✅ Yes     | ⚠️ Limited      | ❌ No   |
| **Simplicity**       | ⚠️ Medium     | ✅ Easy      | ⚠️ Medium  | ✅ Easy         | ✅ Easy |
| **Scalability**      | ✅ Excellent  | ⚠️ Limited   | ⚠️ Limited | ⚠️ Limited      | ❌ Poor |
| **Compliance**       | ✅ Yes        | ❌ No        | ❌ No      | ❌ No           | ❌ No   |
| **Production Ready** | ✅ Yes        | ❌ No        | ⚠️ Maybe   | ⚠️ Maybe        | ❌ No   |


## References

### Vault Documentation
- [Vault Official Documentation](https://www.vaultproject.io/docs)
- [Vault Kubernetes Auth](https://www.vaultproject.io/docs/auth/kubernetes)
- [Vault Agent Injection](https://www.vaultproject.io/docs/platform/k8s/injector)

### Kubernetes RBAC
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes Service Accounts](https://kubernetes.io/docs/concepts/configuration/overview/)

### Industry References
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [CIS Kubernetes Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Decision Date**: November 2025  
**Last Updated**: November 6, 2025  
**Status**: Accepted and Implemented  
**Related Components**: Vault deployment in `tofu/services/vault/` and `kubernetes/bootstrap/resources/vault/`
