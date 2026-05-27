# Portfolio: Homelab Infrastructure Project

> A portfolio piece demonstrating infrastructure engineering, DevOps practices, security-first design, and principled decision-making.

**Table of Contents**
- [Executive Summary](#executive-summary)
- [Skills Demonstrated](#skills-demonstrated)
- [Project Evolution](#project-evolution)
- [Key Achievements](#key-achievements)
- [Problem-Solving Examples](#problem-solving-examples)
- [Lessons Learned](#lessons-learned)

---

## Executive Summary

This homelab project demonstrates **enterprise-grade infrastructure engineering** at a personal scale. It showcases:

- **Architecture & Design**: Layered system design with clear separation of concerns
- **DevOps Practices**: Infrastructure as Code, GitOps, containerisation, Kubernetes
- **Security**: Immutable infrastructure, secrets management, RBAC, audit logging
- **Decision-Making**: Principled technology choices with documented trade-offs
- **Operations**: Tiered backup strategies, disaster recovery planning, operational runbooks
- **Communication**: Clear documentation maintained across multiple audiences

**Project Scope**:
- Hybrid deployment architecture: Ansible + Podman (active) and Kubernetes/Talos (in progress)
- 5 major technology decisions, each captured in an Architecture Decision Record
- 4-tier backup strategy with differentiated RPO/RTO targets
- Multiple self-hosted applications across purpose-built VMs
- 100% Infrastructure as Code

**For detailed architecture information, see**: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Skills Demonstrated

### 1. Infrastructure & Cloud Architecture

**Skills**:
- ✅ Infrastructure as Code (OpenTofu/Terraform)
- ✅ Kubernetes cluster design and management
- ✅ Virtualisation and hypervisor management (Proxmox VE)
- ✅ Network design and configuration
- ✅ Storage architecture and management
- ✅ High availability and disaster recovery planning

**Evidence**:
- Complete infrastructure defined in OpenTofu with reusable modules
- Kubernetes cluster bootstrapped with HA-capable design (Talos Linux)
- Distributed storage with Longhorn for Kubernetes PVs
- ZFS-backed NAS storage for VM data disks
- 4-tier backup strategy with automated scheduling and retention policies
- Documented recovery objectives per data criticality tier

---

### 2. DevOps & Automation

**Skills**:
- ✅ GitOps practices (ArgoCD)
- ✅ Container orchestration (Podman, Kubernetes)
- ✅ Configuration management (Ansible)
- ✅ Infrastructure automation (OpenTofu, Packer)
- ✅ Image building and templating

**Evidence**:
- Ansible roles for application deployment, Podman container lifecycle, PostgreSQL provisioning, and Nginx proxy configuration — all idempotent and version-controlled
- ArgoCD manages Kubernetes applications declaratively from Git
- Packer builds base images for Debian, Ubuntu, and Talos Linux
- OpenTofu provisions VMs, disks, DNS records, and Proxmox resources end-to-end

---

### 3. Security & Compliance

**Skills**:
- ✅ Secrets management (HashiCorp Vault)
- ✅ RBAC and access control
- ✅ Immutable infrastructure design
- ✅ Encryption at rest and in transit
- ✅ Audit logging

**Evidence**:
- Vault is the single source of truth for all secrets — SSH keys, database credentials, API tokens; nothing sensitive is in Git
- Kubernetes RBAC enforces least privilege with service account isolation
- Talos Linux provides an immutable, SSH-free OS for Kubernetes nodes
- Vault audit logging records all secret access

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md)

---

### 4. Decision-Making & Architecture

**Skills**:
- ✅ Technology evaluation and systematic comparison
- ✅ Trade-off analysis and risk assessment
- ✅ Scalability planning
- ✅ Long-term maintainability thinking

**Evidence**:
- 5 Architecture Decision Records, each covering: problem statement, alternatives evaluated, decision rationale, consequences (positive and negative), and risk mitigations
- Decisions cover IaC tooling, Kubernetes distribution, storage, secrets, and backup strategy

---

### 5. Operations & Reliability

**Skills**:
- ✅ Backup and disaster recovery design
- ✅ Incident response procedures
- ✅ Capacity planning
- ✅ Operational runbooks

**Evidence**:
- 4-tier backup strategy with explicit RPO/RTO per tier, mapped to data criticality
- Disaster recovery runbooks for node failure, storage failure, and full cluster rebuild
- Maintenance schedules and escalation procedures documented in OPERATIONS.md

---

### 6. Communication & Documentation

**Skills**:
- ✅ Technical writing for multiple audiences
- ✅ Architecture documentation and diagrams
- ✅ Decision documentation (ADRs)
- ✅ Operational runbook creation

**Evidence**:
- README written for multiple audiences (learning, reference, contribution)
- ARCHITECTURE.md covers layered design, data flows, design principles, and security model
- OPERATIONS.md provides monitoring guidance, troubleshooting steps, and recovery runbooks
- Each ADR documents the full reasoning, not just the outcome

---

## Project Evolution

The project started with a straightforward goal: automate a homelab using Infrastructure as Code. Over time it evolved through several phases:

1. **Foundation**: Proxmox VE as hypervisor; OpenTofu for VM provisioning; Packer for base images
2. **Application layer**: Ansible + Podman for deploying self-hosted applications on Debian VMs
3. **Security hardening**: HashiCorp Vault integrated for centralised secrets management
4. **Backup strategy**: Formalised tiered backup approach with PBS, replacing ad-hoc VM snapshots
5. **Kubernetes**: Talos Linux and Kubernetes being introduced alongside the Ansible/Podman layer for container-native workloads

Each phase was driven by a real operational need rather than technology for its own sake.

---

## Key Achievements

### 1. Hybrid Architecture with a Clear Migration Path

Designed and implemented a layered architecture where Ansible + Podman and Kubernetes coexist without conflict. The Ansible/Podman path keeps existing applications running; the Kubernetes path is built out incrementally. This avoids a high-risk "big bang" migration while still moving toward the target architecture.

### 2. Principled Technology Choices

Every major technology decision is documented in an ADR with the problem context, alternatives evaluated, and the trade-offs accepted. This demonstrates systematic thinking and provides a resource for others making similar decisions.

### 3. Security Built In From the Start

Vault was introduced early, before it was strictly necessary, so that secret management patterns were established before applications proliferated. Talos Linux was chosen specifically for its no-SSH, no-shell, no-package-manager design — security through reduction rather than hardening.

### 4. Cost-Optimised Backup Strategy

Rather than backing everything up at the same frequency, data disks are assigned a tier at provisioning time based on criticality. This is encoded in the OpenTofu module so tier assignment is explicit, auditable, and enforced. Estimated storage savings of 40–50% over a uniform backup approach.

### 5. 100% Infrastructure as Code

Every resource — VMs, data disks, DNS records, Proxmox pools, Proxmox hardware mappings, IAC automation users — is defined in OpenTofu. No manual steps are required to reproduce the infrastructure. PiHole DNS is also managed via OpenTofu's PiHole provider.

---

## Problem-Solving Examples

### Problem 1: Choosing Between OpenTofu and Terraform

**Challenge**: Which IaC tool to use for the long term?

**Analysis**: Terraform has a larger ecosystem and more tutorials, but HashiCorp's licence change in 2023 introduced vendor lock-in risk. OpenTofu is community-governed under the Linux Foundation, maintains full API compatibility with Terraform, and aligns with the open-source philosophy of the project.

**Decision**: OpenTofu. Compatibility with Terraform providers is maintained, so the decision has no practical downside today and eliminates future licence risk.

**See**: [ADR-001](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md)

---

### Problem 2: Kubernetes Distribution for a Homelab

**Challenge**: How to run Kubernetes on Proxmox with strong security and low operational overhead?

**Analysis**: kubeadm and k3s are familiar and well-documented, but both run on mutable operating systems — meaning configuration drift is possible and the SSH attack surface exists. Talos Linux is purpose-built for Kubernetes: immutable OS, API-only access, minimal CVE surface, and atomic updates. The trade-off is a steeper learning curve and different debugging workflows.

**Decision**: Talos Linux. The security and immutability benefits outweigh the learning curve, and the API-driven model is a better fit for Infrastructure as Code.

**See**: [ADR-002](decisions/ADR-002-kubernetes-approach-talos-linux.md)

---

### Problem 3: Persistent Storage for Kubernetes

**Challenge**: How to provide replicated, snapshot-capable storage for Kubernetes applications without the operational complexity of Ceph?

**Analysis**: Ceph is the most capable option but requires dedicated nodes and significant expertise. OpenEBS is flexible but has multiple storage engines with different trade-offs. NFS has no built-in replication. Longhorn is Kubernetes-native, installs via Helm, provides configurable replication and snapshots, and ships with a management UI. It is a CNCF incubating project with active development.

**Decision**: Longhorn. For homelab scale it provides the right balance of capability and operational simplicity.

**See**: [ADR-003](decisions/ADR-003-storage-strategy-longhorn.md)

---

### Problem 4: Backing Up Multiple VMs with Different Criticality

**Challenge**: How to backup a mix of production databases, application state, development environments, and regenerable caches without over-investing in non-critical data?

**Analysis**: A single backup pool with uniform frequency wastes storage on low-criticality data and may under-invest in critical data. A tiered model assigns backup frequency and retention to criticality tiers and makes the assignment explicit in code.

**Decision**: 4-tier strategy. Tier 1 (critical) backs up daily with 30-day retention; Tier 4 (cache/regenerable) backs up quarterly with 180-day retention. Each tier has defined RPO and RTO targets.

**See**: [ADR-005](decisions/ADR-005-tiered-backup-strategy.md)

---

### Problem 5: Managing Secrets Without Storing Them in Git

**Challenge**: How to supply secrets to applications — database passwords, API keys, SSH keys — without ever committing them to version control?

**Analysis**: Kubernetes Secrets are base64-encoded, not encrypted, and are easily leaked if cluster access is gained. Sealed Secrets help with Git storage but are cluster-specific. Vault provides centralised storage, encryption at rest, fine-grained access policies, automatic injection, rotation support, and a full audit log.

**Decision**: HashiCorp Vault. The operational overhead is justified by centralised control and auditability. Vault also serves both the Ansible/Podman and Kubernetes paths, so a single secrets store covers the full infrastructure.

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md)

---

## Lessons Learned

### Start Simple, Evolve Gradually

Kubernetes and Vault were not part of the initial design. They were introduced when there was a clear reason for them. Trying to implement everything at once would have made the system harder to debug and understand. Incremental evolution keeps complexity manageable.

### Document Decisions, Not Just Implementation

Code documents what was done. ADRs document why. The why is harder to reconstruct later and more valuable to future decision-making. Writing ADRs also forces clearer thinking at decision time.

### Security Is Cheaper to Build In Than to Retrofit

Introducing Vault after several applications were already deployed required updating every application's secret handling. Introducing it earlier would have been much cheaper. The same applies to Talos Linux — the immutability constraint shapes decisions from the start.

### Operational Procedures Are As Important As Infrastructure

Infrastructure that can't be operated reliably is not useful. Defining RPO/RTO targets, writing recovery runbooks, and establishing maintenance schedules are as important as the infrastructure design itself.

### Tiered Approaches Beat One-Size-Fits-All

Both the backup strategy and the application architecture benefit from explicit tiering. Treating all data as equally critical wastes resources; treating all orchestration as identical ignores real trade-offs. Making the tiers explicit in code (backup tier assignment in OpenTofu) removes ambiguity.

### Open-Source Governance Matters for Long-Term Projects

The OpenTofu decision was driven partly by governance concerns. For infrastructure that will run for years, the project's governance model is as relevant as its current feature set.

---

**Last Updated**: May 2026
**Status**: Active
**Maintainer**: Eduard