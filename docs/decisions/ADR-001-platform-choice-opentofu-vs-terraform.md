# ADR-001: Platform Choice (OpenTofu vs Terraform)

## Status
**Accepted**

## Context

### Problem Statement
The homelab infrastructure requires a robust Infrastructure-as-Code (IaC) tool to provision and manage virtual machines, networking, storage, and cloud resources across Proxmox VE. The choice of IaC platform is foundational to the entire infrastructure strategy and will impact:

- Long-term maintainability and vendor lock-in
- Community support and ecosystem maturity
- Licensing and cost implications
- Feature parity and innovation velocity
- Ability to fork and customize the tool itself

### Constraints and Assumptions

**Constraints:**
- Must support Proxmox VE provider for VM provisioning
- Must support Kubernetes provider for cluster configuration
- Must be open-source (GPL-3.0 license alignment)
- Must support modular, reusable components
- Must have strong community support
- Must support state management and drift detection

**Assumptions:**
- The infrastructure will grow and evolve over time
- Long-term maintainability is more important than short-term convenience
- Community-driven development is preferable to vendor-controlled
- The tool should be forkable and customizable if needed

### Requirements That Influenced the Decision

1. **Open-Source Governance**: Preference for community-driven development
2. **Vendor Independence**: Avoid lock-in to HashiCorp's licensing changes
3. **Feature Parity**: Must support all required providers
4. **Ecosystem**: Strong provider ecosystem for Proxmox, Kubernetes, Vault
5. **Modularity**: Support for reusable modules and composition
6. **State Management**: Robust state handling and drift detection
7. **Documentation**: Comprehensive documentation and examples

## Decision

**Chosen: OpenTofu**

OpenTofu was selected as the primary Infrastructure-as-Code tool for this homelab infrastructure.

### Key Factors That Led to This Choice

#### 1. Open-Source Governance Model
- **OpenTofu**: Community-driven, Linux Foundation project
  - Governed by community steering committee
  - No single vendor control
  - Transparent decision-making process
  - Forking rights preserved
  
- **Terraform**: Vendor-controlled by HashiCorp
  - Subject to licensing changes (BSL → BUSL)
  - Vendor can unilaterally change direction
  - Community input is advisory only

**Impact**: OpenTofu provides long-term independence and aligns with open-source philosophy.

#### 2. Licensing and Cost Implications
- **OpenTofu**: MPL 2.0 license
  - No licensing restrictions
  - No cost implications
  - Can be used commercially without restrictions
  - Can be forked and modified
  
- **Terraform**: BSL → BUSL (Business Source License)
  - Restrictions on commercial use
  - Potential cost implications for enterprises
  - Licensing terms subject to change
  - Limited modification rights

**Impact**: OpenTofu eliminates licensing concerns and provides cost certainty.

#### 3. Feature Parity and Provider Support
- **OpenTofu**: 
  - Full compatibility with Terraform providers
  - Proxmox provider: ✅ Fully supported
  - Kubernetes provider: ✅ Fully supported
  - Talos provider: ✅ Fully supported
  - Vault provider: ✅ Fully supported
  
- **Terraform**:
  - All same providers available
  - No feature advantage

**Impact**: OpenTofu provides equivalent functionality with better governance.

#### 4. Community and Ecosystem
- **OpenTofu**:
  - Growing community (Linux Foundation backing)
  - Active development and contributions
  - Regular releases and updates
  - Strong momentum in 2024-2025
  
- **Terraform**:
  - Larger existing community
  - Mature ecosystem
  - More third-party tools and integrations

**Impact**: OpenTofu has sufficient community support while offering better long-term prospects.

#### 5. Modularity and Reusability
Both tools support:
- Module composition and reuse
- Variable parameterization
- Output values and data sources
- State management

**Impact**: No differentiation; both equally capable.

#### 6. Strategic Alignment
- **Project Philosophy**: This homelab demonstrates modern DevOps practices
- **Open-Source Values**: GPL-3.0 license alignment
- **Community Contribution**: OpenTofu represents community-driven infrastructure
- **Educational Value**: Demonstrates principled technology choices

**Impact**: OpenTofu choice reinforces project values and educational mission.

## Consequences

### Positive

#### 1. Vendor Independence
- **Benefit**: No risk of licensing changes or vendor lock-in
- **Impact**: Infrastructure remains under our control indefinitely
- **Timeline**: Immediate and permanent

#### 2. Cost Certainty
- **Benefit**: No licensing costs or restrictions
- **Impact**: Reduces operational costs and complexity
- **Timeline**: Immediate and ongoing

#### 3. Community Alignment
- **Benefit**: Aligns with open-source community values
- **Impact**: Attracts contributors and users who value open-source
- **Timeline**: Immediate and ongoing

#### 4. Forking Rights
- **Benefit**: Can fork and customize if needed
- **Impact**: Ultimate control over the tool
- **Timeline**: Available if needed in future

#### 5. Long-Term Viability
- **Benefit**: Linux Foundation backing ensures long-term support
- **Impact**: Confidence in tool's future
- **Timeline**: 5-10+ years

#### 6. Educational Value
- **Benefit**: Demonstrates principled technology choices
- **Impact**: Valuable learning for infrastructure engineers
- **Timeline**: Immediate and ongoing

### Negative

#### 1. Smaller Community
- **Drawback**: Fewer users and third-party tools compared to Terraform
- **Impact**: Potentially fewer Stack Overflow answers and tutorials
- **Mitigation**: Terraform documentation is largely compatible; community is growing rapidly

#### 2. Ecosystem Maturity
- **Drawback**: Newer project (forked from Terraform in 2023)
- **Impact**: Some edge cases may not be as well-tested
- **Mitigation**: Terraform provider ecosystem is mature; OpenTofu uses same providers

#### 3. Tool Ecosystem
- **Drawback**: Fewer third-party tools (Terragrunt, Atlantis, etc.) have native OpenTofu support
- **Impact**: May need to use Terraform-compatible wrappers
- **Mitigation**: Most tools work with OpenTofu through Terraform compatibility mode

#### 4. Learning Resources
- **Drawback**: Fewer OpenTofu-specific tutorials and courses
- **Impact**: Learning curve may be slightly steeper
- **Mitigation**: Terraform documentation is largely applicable; community documentation is growing

### Risks and Mitigation

#### Risk 1: Community Adoption Lag
**Risk**: OpenTofu may not achieve critical mass of adoption
**Probability**: Medium
**Impact**: Reduced ecosystem support and third-party tools
**Mitigation**:
- Monitor community growth and adoption metrics
- Contribute to OpenTofu project to help drive adoption
- Maintain compatibility with Terraform for portability
- Document any workarounds needed

#### Risk 2: Provider Compatibility Issues
**Risk**: Some Terraform providers may not work perfectly with OpenTofu
**Probability**: Low
**Impact**: May need to use Terraform for specific providers
**Mitigation**:
- Test all providers in sandbox environment before production use
- Maintain Terraform as fallback option
- Report compatibility issues to OpenTofu project
- Contribute fixes if needed

#### Risk 3: Tool Fragmentation
**Risk**: OpenTofu and Terraform may diverge significantly
**Probability**: Low
**Impact**: Code may not be portable between tools
**Mitigation**:
- Follow OpenTofu compatibility guidelines
- Avoid OpenTofu-specific features when possible
- Maintain ability to migrate to Terraform if needed
- Monitor divergence and adjust strategy if needed

#### Risk 4: Licensing Changes
**Risk**: OpenTofu licensing could change
**Probability**: Very Low (Linux Foundation backing)
**Impact**: Would need to reconsider tool choice
**Mitigation**:
- Monitor OpenTofu governance and licensing
- Maintain ability to fork if needed
- Contribute to governance to influence decisions

## Alternatives Considered

### Alternative 1: Terraform (HashiCorp)
**Pros:**
- Larger community and ecosystem
- More mature and battle-tested
- More third-party tools and integrations
- More learning resources and tutorials

**Cons:**
- Vendor-controlled by HashiCorp
- Subject to licensing changes (BSL/BUSL)
- Potential cost implications
- Limited modification rights
- Misalignment with open-source philosophy

**Why Rejected**: Licensing concerns and vendor lock-in outweigh ecosystem advantages. For a long-term infrastructure project, vendor independence is more important than ecosystem maturity.

### Alternative 2: Pulumi
**Pros:**
- General-purpose programming language support (Python, Go, TypeScript)
- More expressive than HCL
- Strong type safety
- Good for complex logic

**Cons:**
- Steeper learning curve (requires programming knowledge)
- Smaller community than Terraform
- Less mature for infrastructure patterns
- Requires language runtime
- More complex state management

**Why Rejected**: Adds unnecessary complexity for this use case. HCL is sufficient and more accessible. Pulumi's advantages don't outweigh the added complexity.

### Alternative 3: AWS CDK / Cloud-Specific Tools
**Pros:**
- Native integration with cloud provider
- Excellent documentation and support
- Large community

**Cons:**
- Lock-in to specific cloud provider
- Not suitable for multi-cloud or on-premises
- Doesn't support Proxmox
- Defeats purpose of infrastructure independence

**Why Rejected**: Incompatible with on-premises Proxmox infrastructure. Would require complete rewrite for different cloud provider.

### Alternative 4: Ansible
**Pros:**
- Agentless architecture
- Simple YAML syntax
- Good for configuration management
- Large community

**Cons:**
- Not designed for infrastructure provisioning
- Lacks state management
- No drift detection
- Imperative rather than declarative
- Poor for complex infrastructure

**Why Rejected**: Ansible is a configuration management tool, not an IaC tool. Lacks essential features like state management and drift detection. Better used in combination with IaC tool.

### Alternative 5: Bicep / ARM Templates
**Pros:**
- Native Azure integration
- Good for Azure-specific deployments

**Cons:**
- Azure-only
- Not suitable for Proxmox
- Vendor lock-in
- Smaller community

**Why Rejected**: Azure-specific; incompatible with Proxmox infrastructure.

## Comparison Matrix

| Criteria               | OpenTofu  | Terraform    | Pulumi    | Ansible   |
| ---------------------- | --------- | ------------ | --------- | --------- |
| **Open Source**        | ✅ Yes     | ⚠️ Restricted | ✅ Yes     | ✅ Yes     |
| **Vendor Independent** | ✅ Yes     | ❌ No         | ✅ Yes     | ✅ Yes     |
| **Proxmox Support**    | ✅ Yes     | ✅ Yes        | ✅ Yes     | ⚠️ Limited |
| **State Management**   | ✅ Yes     | ✅ Yes        | ✅ Yes     | ❌ No      |
| **Drift Detection**    | ✅ Yes     | ✅ Yes        | ✅ Yes     | ❌ No      |
| **Modularity**         | ✅ Yes     | ✅ Yes        | ✅ Yes     | ⚠️ Limited |
| **Community Size**     | ⚠️ Growing | ✅ Large      | ⚠️ Medium  | ✅ Large   |
| **Learning Curve**     | ✅ Easy    | ✅ Easy       | ❌ Steep   | ✅ Easy    |
| **Ecosystem**          | ⚠️ Growing | ✅ Mature     | ⚠️ Growing | ✅ Mature  |
| **Cost**               | ✅ Free    | ⚠️ Restricted | ⚠️ Paid    | ✅ Free    |

## References

### OpenTofu Documentation
- [OpenTofu Official Documentation](https://opentofu.org/docs/)
- [OpenTofu GitHub Repository](https://github.com/opentofu/opentofu)
- [OpenTofu Governance](https://opentofu.org/docs/intro/governance/)

### Terraform Documentation
- [Terraform Official Documentation](https://www.terraform.io/docs/)
- [Terraform Providers](https://registry.terraform.io/)

### Industry References
- [Infrastructure as Code Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [State Management in IaC](https://www.terraform.io/docs/language/state/)
- [Modular Infrastructure Patterns](https://www.terraform.io/docs/language/modules/)

---

**Decision Date**: November 2025  
**Last Updated**: November 6, 2025  
**Status**: Accepted and Implemented  
**Related Components**: All infrastructure provisioning in `tofu/` directory
