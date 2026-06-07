# ADR-007: Infrastructure Automation — OpenTofu and Ansible Tool Selection

## Status
**Accepted**

---

## Context

### Problem Statement

The homelab infrastructure requires a robust Infrastructure-as-Code (IaC) approach to provision and manage virtual machines, networking, storage, and services across Proxmox VE. Two categories of work compete for tooling attention: provisioning (creating, updating, deleting infrastructure objects) and bootstrapping/configuration (installing packages, configuring services, deploying applications).

Without a clear boundary between tools, the system tends to blur — Ansible gets used for lifecycle management where it lacks state tracking, and OpenTofu gets used for configuration tasks where its provider model is a poor fit. This drift leads to tombstone code, invisible drift, and objects that cannot be cleanly deleted.

**What problem are we solving?**
Establishing a clear, enforceable boundary between OpenTofu (provisioning and lifecycle) and Ansible (configuration and deployment), so that each tool is used where it is strongest and absence of code reliably means deletion of the object.

**Why is this decision critical?**
The choice determines the deletion model for every managed object. If Ansible is the owner, removing a resource requires dead `state: absent` tombstone code. If OpenTofu is the owner, removing the block is sufficient. For infrastructure with real lifecycle needs, the Ansible model is the wrong default.

**What are the consequences of not making a decision?**
Objects will be managed in both tools simultaneously, or responsibility will drift over time as new services are added. Drift becomes invisible. Deletion requires tombstone code that accumulates and becomes a maintenance burden and a source of errors.

**What areas of the infrastructure does this affect?**
VM provisioning, network configuration, DNS, storage, service deployment, application configuration, and ongoing updates to all of the above.

### Constraints and Assumptions

#### Constraints

- Must support Proxmox VE provider for VM and LXC provisioning
- Must support HashiCorp Vault for credential management (read-only data source is sufficient)
- Must support Pi-hole for DNS record management
- Must be open-source (GPL-3.0 / Apache 2.0 alignment)
- Must support state management and drift detection for provisioned resources
- Must support configuration management for Debian-based VMs
- Must support modular, reusable components

#### Assumptions

- The infrastructure will grow and evolve over time — initial choices compound
- Long-term maintainability is more important than short-term convenience
- Community-driven tooling is preferable to vendor-controlled (no Terraform Cloud / Ansible Tower)
- The homelab will have multiple VMs and services requiring both provisioning and configuration
- Deleted resources should be expressed by removing code, not adding tombstone code

### Requirements That Influenced the Decision

1. **Deletion Model**: Absence of code must mean deletion of the object — no tombstone code
2. **State Management**: Tool must track current state and detect drift via `plan` / `apply`
3. **Provider Ecosystem**: Mature providers for Proxmox, Vault, Pi-hole must exist
4. **Configuration Model**: Must handle package installation, service management, config templating, and app deployment
5. **Bootstrap Capability**: Must be able to configure a freshly provisioned VM via SSH
6. **Idempotency**: Changes must be safely re-applicable without side effects
7. **Separation of Concerns**: Provisioning and configuration must be owned by distinct tools

---

## Decision

**Chosen: Layered approach — OpenTofu for provisioning and lifecycle, Ansible for configuration and deployment**

OpenTofu owns all resource creation, updates, and deletion for the infrastructure substrate. Ansible owns all package installation, service configuration, and application deployment on provisioned hosts.

### Layer 1 — Platform (Day 0): OpenTofu

Provision the substrate everything else runs on. VMs, networking, storage, DNS. OpenTofu owns all resource lifecycle here — creation, updates, and deletion.

User-data passed to VMs at provision time must be **minimal**. It exists only to make the machine reachable for Ansible:
- Set hostname
- Drop SSH key / create service account
- Ensure Python is present

If user-data exceeds ~20 lines, it is doing too much. Any change to user-data requires VM replacement — by keeping it minimal, this is a rare and low-impact event.

### Layer 2 — App (Day 1+): Ansible

Ansible installs, configures, and updates services on provisioned hosts. This covers:
- Package installation
- OS-level configuration (users, sudoers, sysctl, mounts, firewall rules)
- Service management and config file templating
- Application deployment and updates

### Key Factors That Led to This Choice

#### 1. Deletion Model
- **OpenTofu**: Removing a resource block + `tofu apply` deletes the object. No tombstone code needed.
- **Ansible**: Requires explicit `state: absent` tasks to delete objects. Absence of a task does nothing.

- **Impact**: For infrastructure with real lifecycle needs, Ansible's model creates dead code and silent failures when deletion tasks are forgotten. OpenTofu's model is the correct default.

#### 2. State Management and Drift Detection
- **OpenTofu**: Tracks state in `.tfstate`. `tofu plan` shows exact diff before applying.
- **Ansible**: Stateless push model. No built-in drift detection.

- **Impact**: OpenTofu can detect when a resource has drifted from desired state. Ansible cannot — it only reports task-level changes, not overall resource state.

#### 3. Provider Ecosystem for Platform Services

Current providers in use:

| Provider              | Usage                                                                |
| --------------------- | -------------------------------------------------------------------- |
| `bpg/proxmox`         | VMs, LXCs, storage pools, network bridges                            |
| `ryanwholey/pihole`   | DNS records                                                          |
| `opentofu/vault`      | Read-only data source (`data.vault_kv_secret_v2`) for SSH key lookup |
| `cyrilgdn/postgresql` | Database provisioning for apps                                       |
| `loafoe/ssh`          | SSH key distribution to VMs                                          |

Note: The `opentofu/vault` provider only has data sources, no resource types. Vault lifecycle objects (policies, auth mounts, secret engines, roles) are managed via other tools.

Note: Proxmox Backup Server is a plain VM with a bootstrap script. Its datastores are additional disks on that VM, not PBS provider objects.

Note: Nginx Proxy Manager proxy hosts are managed by the `nginx_proxy_manager` Ansible role, not by OpenTofu.

- **Impact**: Where a mature provider exists and the object has lifecycle needs, OpenTofu is the right tool. Where no provider exists, Ansible fills the gap.

#### 4. Ansible's Strength in Configuration Management
- **Ansible**: Purpose-built for package installation, service management, config templating, and app deployment. Idempotent by design.
- **OpenTofu `local-exec` / `remote-exec`**: Poor substitutes for a proper configuration management tool. Last resort, not a pattern.

- **Impact**: Using Ansible for Day 1+ configuration is the correct tool for the job. OpenTofu should not be used for configuration tasks via provisioners.

#### 5. Bootstrap as a Bridge
- Minimal user-data at VM provision time makes machines reachable for Ansible. No other bootstrap mechanism needed.

- **Impact**: Keeping user-data minimal avoids the anti-pattern of configuration embedded in cloud-init that cannot be updated without VM replacement.

#### 6. Single Owner Per Object
- **Rule**: Each resource has one owner. Do not manage the same object in both tools.

- **Impact**: Overlapping ownership leads to conflicts, drift, and confusion about which tool to update.

---

## Consequences

### Positive

#### 1. Clean Deletion Model
- **Benefit**: Removing a resource block from OpenTofu configuration deletes the object on next `tofu apply`. No tombstone code accumulation.
- **Impact**: Infrastructure code remains clean over time. Deletion is expressed by absence, not presence.
- **Timeline**: Immediate — applies to all newly provisioned resources.

#### 2. Drift Detection via `tofu plan`
- **Benefit**: State file enables exact diff of desired vs actual infrastructure before any change is applied.
- **Impact**: Changes to infrastructure are intentional and auditable. Accidental drift is surfaced before it causes problems.
- **Timeline**: Immediate — available on every `tofu plan` run.

#### 3. Clear Tool Boundaries Reduce Decision Fatigue
- **Benefit**: Engineers do not need to decide where a new resource belongs — the rule is simple: provisioning and lifecycle is OpenTofu, configuration and deployment is Ansible.
- **Impact**: Faster onboarding, fewer boundary disputes, consistent infrastructure code across the homelab.
- **Timeline**: Immediate and ongoing.

#### 4. Ansible's Maturity for OS-Level Configuration
- **Benefit**: Ansible has mature modules for package management, service management, user administration, and config templating on Debian.
- **Impact**: Reliable, idempotent configuration of all application services after VM provisioning.
- **Timeline**: Immediate for all Day 1+ workloads.

#### 5. Modular OpenTofu Structure
- **Benefit**: Reusable `virtual_machine` module with cloud-init bootstrap handles all VM provisioning consistently.
- **Impact**: Adding a new VM requires only adding an entry to `local.virtual_machines` in `vms.tf`. All common defaults are centralized.
- **Timeline**: Immediate for future VMs.

#### 6. Separation Reduces Blast Radius
- **Benefit**: VM resize/re-image requires `tofu apply` + Ansible re-run. App config changes require Ansible only. No cross-tool dependencies for routine changes.
- **Impact**: Changes are scoped to the layer that owns them. No unnecessary re-provisioning of VMs when app config changes.
- **Timeline**: Immediate and ongoing.

### Negative

#### 1. Two Tools to Learn and Maintain
- **Drawback**: Both OpenTofu and Ansible must be kept up to date, configured correctly, and understood by operators.
- **Impact**: Slightly higher cognitive load compared to a single tool. Both toolchains need inventory, variable management, and secret handling.
- **Mitigation**: Document the boundary clearly (this ADR). Keep both toolchains minimal and focused. Share variable definitions between tools where possible.

#### 2. OpenTofu State Must Be Protected
- **Drawback**: `.tfstate` contains sensitive values (API tokens, IP addresses). If lost, infrastructure state is lost. If leaked, credentials are compromised.
- **Impact**: State file must be backed up and not committed to version control with secrets.
- **Mitigation**: Use Vault or a secrets manager for sensitive values. Keep state backups in a safe location (ZFS snapshot + off-site sync).

#### 3. Provider Coverage Is Incomplete
- **Drawback**: Not every service has a mature OpenTofu provider. Vault's provider is data-source-only. NPM has no provider. PBS has no provider.
- **Impact**: Some objects that theoretically belong in OpenTofu (lifecycle-managed objects) are managed in Ansible instead, violating the pure model.
- **Mitigation**: Accept pragmatic hybrid approach. Where no provider exists, Ansible manages the object with `state: absent` as needed. Revisit when providers mature.

#### 4. Ansible Has No Drift Detection for Objects It Manages
- **Drawback**: If something drifts outside of Ansible's last run, it is invisible until the next playbook run.
- **Impact**: Configuration drift on services managed by Ansible is not detected proactively.
- **Mitigation**: Run Ansible periodically (e.g., weekly) or on-demand after changes. For critical services, consider adding drift-checking to the run.

#### 5. VM Replacement on User-Data Change
- **Drawback**: Any change to user-data requires VM replacement since cloud-init runs only at first boot.
- **Impact**: Significant changes to bootstrap requirements force VM re-provisioning, which triggers data migration concerns.
- **Mitigation**: Keep user-data minimal (hostname, SSH key, Python only). All real configuration happens via Ansible.

### Risks and Mitigation

#### Risk 1: State File Corruption or Loss
**Risk**: The `.tfstate` file is the source of truth for all OpenTofu-managed resources. Corruption or loss means OpenTofu loses track of what exists.
**Probability**: Low
**Impact**: High — manual reconciliation required; resources may be orphaned or accidentally deleted
**Mitigation**:
- Keep `.tfstate` on ZFS with regular snapshots
- Sync state to off-site storage (Hetzner BX11)
- Never manually edit state — use `tofu state mv` for migrations
- Keep etcd backup for critical infrastructure state

#### Risk 2: Provider Bugs Causing Unintended Resource Deletion
**Risk**: A bug in a provider (e.g., `bpg/proxmox`) could cause OpenTofu to delete resources that should be preserved.
**Probability**: Very Low
**Impact**: High — production VMs could be destroyed
**Mitigation**:
- Always run `tofu plan` and review output before `tofu apply`
- Keep critical VMs with `backup_tier = 0` (no backup — treat as ephemeral)
- Use `confirm: true` or equivalent safeguards for destructive operations

#### Risk 3: Tool Boundary Blur Over Time
**Risk**: New services are added and the boundary rule is bent "just this once", accumulating inconsistencies.
**Probability**: Medium
**Impact**: Medium — mixed ownership makes changes harder to reason about
**Mitigation**:
- Reference this ADR when adding new resources
- If a service fits the OpenTofu layer rule (lifecycle + mature provider), add it there
- If no provider exists, document the exception and the reasoning

#### Risk 4: Ansible Password or Key Exposure in Playbooks
**Risk**: Ansible playbooks that include passwords or API tokens in plain text risk exposure if committed to version control.
**Probability**: Low
**Impact**: High — credential exposure could compromise infrastructure
**Mitigation**:
- Use `ansible-vault` for sensitive variables
- Use Vault data sources for credentials where possible
- Never commit plaintext secrets to the repository

---

## Alternatives Considered

### Alternative 1: Ansible Only

**Pros:**
- Single tool to learn, maintain, and configure
- Mature configuration management with excellent Debian support
- Idempotent by design for configuration tasks
- No state file to protect or manage
- Large community and extensive galaxy roles

**Cons:**
- Stateless model requires `state: absent` tombstone code for deletion
- No built-in drift detection — drift is invisible between runs
- Not designed for resource lifecycle management
- No declarative diff against desired state

**Why Rejected**: Stateless deletion model is the wrong model for infrastructure with real lifecycle needs. Tombstone code accumulates and becomes error-prone. No drift detection means configuration drift is invisible.

### Alternative 2: OpenTofu Only

**Pros:**
- Single tool for both provisioning and configuration
- State management and drift detection for all resources
- Declarative diff via `tofu plan`
- Strong provider ecosystem for major platforms

**Cons:**
- `local-exec` and `remote-exec` provisioners are poor configuration management tools
- No mature provider for many Day 1+ configuration tasks (package management, service configuration)
- Configuration management requires workarounds that are fragile and hard to maintain
- Provider coverage gaps leave gaps in the configuration model

**Why Rejected**: OpenTofu is not a configuration management tool. Using `remote-exec` for package installation and service configuration is an anti-pattern that leads to fragile, hard-to-maintain configurations.

### Alternative 3: Bash Scripts / Manual Configuration

**Pros:**
- Maximum flexibility — can do anything
- No tool-specific syntax to learn
- No state file to manage

**Cons:**
- No state tracking — what exists is whatever the last script ran
- No idempotency — scripts may not be safely re-runnable
- No diff — cannot see what would change before running
- No drift detection — changes are invisible until they cause problems
- Becomes a bespoke system that only the author understands
- No separation between provisioning and configuration

**Why Rejected**: Infrastructure-as-code requires state tracking, idempotency, and diff. A collection of scripts provides none of these. Manual configuration does not scale and cannot be audited.

---

## Comparison Matrix

| Criteria                             | OpenTofu + Ansible   | Ansible Only              | OpenTofu Only              |
| ------------------------------------ | -------------------- | ------------------------- | -------------------------- |
| **Deletion Model: absence = delete** | ✅ Yes                | ❌ Tombstone code required | ✅ Yes                      |
| **State Management**                 | ✅ OpenTofu has state | ❌ Stateless               | ✅ Yes                      |
| **Drift Detection**                  | ✅ `tofu plan`        | ❌ None                    | ✅ Yes                      |
| **Mature Proxmox Provider**          | ✅ `bpg/proxmox`      | N/A (not IaC)             | ✅ Yes                      |
| **Configuration Management**         | ✅ Ansible for Day 1+ | ✅ Yes                     | ❌ `remote-exec` workaround |
| **Provider Ecosystem**               | ✅ Multiple providers | ⚠️ Modules only            | ✅ Yes                      |
| **Idempotency**                      | ✅ Both tools         | ✅ Yes                     | ⚠️ Provisioners fragile     |
| **Learning Curve**                   | ⚠️ Two tools          | ✅ Low                     | ✅ Low                      |
| **Operational Overhead**             | ⚠️ Two toolchains     | ✅ Low                     | ✅ Low                      |
| **Open-Source**                      | ✅ Both               | ✅ Yes                     | ✅ Yes                      |

---

## References

### OpenTofu / Terraform
- [OpenTofu Official Documentation](https://opentofu.org/docs/)
- [OpenTofu GitHub Repository](https://github.com/opentofu/opentofu)
- [bpg/proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [opentofu/vault Provider](https://registry.terraform.io/providers/opentofu/vault/latest) — data sources only
- [ryanwholey/pihole Provider](https://registry.terraform.io/providers/ryanwholey/pihole/latest)

### Ansible
- [Ansible Official Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Community Documentation](https://docs.ansible.com/ansible/latest/index.html)

### Infrastructure as Code Best Practices
- [Terraform State Best Practices](https://developer.hashicorp.com/terraform/language/state)
- [Infrastructure as Code: What Is IaC?](https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac)

### Related ADRs
- ADR-001: [Proxmox VE as Virtualization Platform](./ADR-001-proxmox-ve.md)
- ADR-006: [Backup Strategy and PBS](./ADR-006-backup-strategy.md)

---

## Decision Metadata

**Decision Date**: June 2026  
**Last Updated**: June 2026  
**Status**: Accepted  
**Decision Owner**: Eduard  
**Related ADRs**: ADR-001 (Proxmox VE), ADR-006 (Backup Strategy)
