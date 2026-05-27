# Homelab Architecture Documentation

> Comprehensive technical architecture of the homelab infrastructure, including component relationships, data flow, design decisions, and operational characteristics.
>
> **This document describes the ACTUAL deployed state of the homelab, not aspirational or planned components.**

**Table of Contents**
- [System Overview](#system-overview)
- [Architecture Layers](#architecture-layers)
- [Component Details](#component-details)
- [Data Flow](#data-flow)
- [Design Principles](#design-principles)
- [Performance Characteristics](#performance-characteristics)
- [Scalability Considerations](#scalability-considerations)
- [Security Architecture](#security-architecture)
- [Disaster Recovery](#disaster-recovery)

---

## System Overview

The homelab infrastructure is organized into **4 distinct layers**, each with specific responsibilities:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  (Plane, Immich, Paperless NGX, Docmost, Leaf Wiki,        │
│   Pi-hole)                                                  │
├─────────────────────────────────────────────────────────────┤
│                    Container Layer                           │
│  (Podman, Ansible-managed containers, Systemd services,     │
│   Nginx Proxy Manager)                                      │
├─────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                      │
│  (OpenTofu, Packer, Ansible, Vault, PostgreSQL)             │
├─────────────────────────────────────────────────────────────┤
│                    Virtualization Layer                      │
│  (Proxmox VE, KVM/QEMU, ZFS, Virtual Machines,             │
│   Virtual Networks)                                         │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision           | Choice          | Rationale                                                          |
| ------------------ | --------------- | ------------------------------------------------------------------ |
| Hypervisor         | Proxmox VE      | KVM/QEMU with ZFS, web UI, API-driven                              |
| IaC Tool           | OpenTofu        | Open-source Terraform fork, no license restrictions                |
| Container Runtime  | Podman          | Daemonless, rootless, systemd-integrated, no orchestrator overhead |
| Configuration Mgmt | Ansible         | Agentless, push-based, idempotent                                  |
| Secrets Management | HashiCorp Vault | Centralized, audited, API-driven                                   |
| DNS                | Pi-hole         | Network-wide ad blocking + DHCP                                    |

**See**: [ADR-001](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md) for OpenTofu selection rationale

---

## Architecture Layers

### 1. Virtualization Layer

**Purpose**: Provide virtual compute, storage, and networking resources

**Components**:
- **Proxmox VE**: Hypervisor (single-node) and VM management
- **KVM/QEMU**: Virtual machine execution
- **ZFS Storage Pools**: `zfs-nas`, `vm-os-pool` for VM disks and backups
- **Virtual Networks**: Isolated network segments for VM communication

**Characteristics**:
- Bare-metal hypervisor for maximum performance
- Web UI and API for management
- ZFS snapshots and replication for backup
- Single physical host (`homeserver`) running all VMs

**Provisioned VMs** (via OpenTofu):

| VM Name    | Role                      | CPU | RAM  | Data Disks                                          |
| ---------- | ------------------------- | --- | ---- | --------------------------------------------------- |
| `games`    | Gaming Server             | 4   | 8 GB | —                                                   |
| `utility`  | Utility Server            | 2   | 2 GB | —                                                   |
| `database` | Databases                 | 4   | 8 GB | postgres (20 GB), vectorchord (10 GB)               |
| `backup`   | Proxmox Backup Server     | 2   | 4 GB | backup (1.5 TB), config (1 GB)                      |
| `media`    | Media Applications        | 2   | 4 GB | immich (1 TB), archives (44 GB)                     |
| `office`   | Productivity Applications | 4   | 8 GB | plane (50 GB), docmost (100 GB), paperless (100 GB) |
| `pihole`   | DNS / DHCP / NPM          | —   | —    | Provisioned via OpenTofu pihole module              |

Additional hardware hosts managed via Ansible: **fritzbox** (router), **printer**, **homeserver** (Proxmox host itself).

**See**: `tofu/vms.tf` for VM definitions, `ansible/inventory/hosts.yml` for inventory

---

### 2. Infrastructure Layer

**Purpose**: Automate infrastructure provisioning, configuration management, and secrets handling

**Components**:
- **OpenTofu**: Infrastructure as Code for VM and network provisioning
- **Packer**: VM image building and templating (Debian base images)
- **Ansible**: Configuration management, application deployment, secrets injection
- **Vault**: Centralized secrets management (standalone, used by OpenTofu and Ansible)
- **PostgreSQL**: Database server (Podman container on `database` VM, standard + pgvector instances)

#### OpenTofu Modules

```
tofu/
├── modules/
│   ├── virtual_machine/          # VM provisioning (CPU, RAM, disks, cloud-init)
│   └── cron_remote/              # Remote cron job management
├── proxmox/                      # Proxmox cluster configuration
├── pihole/                       # Pi-hole VM/DNS provisioning
├── data/                         # Scripts and templates
├── vms.tf                        # VM definitions (games, utility, database, backup, media, office)
├── provider.tf                   # Provider configs (Proxmox, Pi-hole, Vault)
├── variables.tf                  # Input variables
└── versions.tf                   # Version constraints
```

#### Ansible Roles

```
ansible/roles/
├── apps/
│   ├── docmost/                  # Document collaboration (Podman container)
│   ├── immich/                   # Photo/video management (Podman containers)
│   ├── leafwiki/                 # Wiki (Podman container)
│   ├── paperless/                # Document management (Podman containers)
│   └── plane/                    # Project management (Podman containers)
├── nginx_proxy_manager/          # NPM reverse proxy configuration
├── os_debian/                    # OS-level configuration (disks, packages)
├── podman/                       # Podman installation and configuration
├── postgres/                     # PostgreSQL database provisioning
├── retrogames/                   # Retro gaming emulation setup
└── vault/                        # Vault secrets store/fetch (utility role)
```

#### Ansible Playbooks

```
ansible/playbooks/
├── site.yml                      # Main entry point (proxy → databases → apps)
├── proxy.yml                     # Nginx Proxy Manager host configuration
├── databases.yml                 # PostgreSQL instances (standard + vectorchord)
├── apps.yml                      # Application deployment (office → media)
├── retrogames.yml                # Retro gaming setup
└── destroy-leafwiki.yml          # Leaf Wiki teardown
```

**Workflow**:
1. **OpenTofu** provisions VMs on Proxmox with cloud-init
2. **Ansible** runs `site.yml` to configure OS, deploy databases, and deploy applications
3. **Vault** stores and provides secrets (database passwords, app secrets, API keys) to Ansible and OpenTofu
4. **Nginx Proxy Manager** configures reverse proxy rules for all services

**Characteristics**:
- Declarative infrastructure via OpenTofu
- Idempotent configuration via Ansible
- Version-controlled (Git)
- Modular, reusable roles and modules

**See**:
- [ADR-001](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md) for OpenTofu vs Terraform
- `tofu/` for implementation
- `ansible/` for playbooks and roles

---

### 3. Container Layer

**Purpose**: Run containerized applications with Podman, managed declaratively via Ansible

**Components**:
- **Podman**: Container runtime (daemonless, rootless)
- **Podman systemd services**: Auto-start containers on boot
- **Ansible**: Deploys and manages container lifecycles
- **Nginx Proxy Manager**: Reverse proxy (runs as Podman container on Pi-hole VM)

**Why Podman (not Docker or Kubernetes)**:
- Daemonless architecture (no central daemon, no single point of failure)
- Rootless by default (better security posture)
- Native systemd integration (containers as systemd services)
- No orchestrator overhead (appropriate for single-VM application workloads)
- Drop-in Docker-compatible CLI (alias `docker=podman`)

**Deployment Model**:

```
Ansible Control Node
    │
    ├── office VM ─── Podman containers:
    │   ├── Plane (project management)
    │   ├── Leaf Wiki (wiki)
    │   └── Paperless NGX (document management)
    │
    ├── media VM ─── Podman containers:
    │   └── Immich (photo/video management)
    │       ├── immich-server
    │       ├── immich-microservices
    │       ├── immich-machine-learning
    │       └── (supporting containers)
    │
    ├── database VM ─── Podman containers:
    │   ├── postgres (standard, port 5432)
    │   └── postgres-vectorchord (pgvector, port 5433)
    │
    └── pihole VM ─── Podman containers:
        ├── Pi-hole (DNS/DHCP)
        └── Nginx Proxy Manager (reverse proxy)
```

**Container Lifecycle Management**:
- Ansible playbooks define desired container state (image, volumes, ports, env vars)
- Ansible generates systemd unit files for each container/Pod
- Podman runs containers under dedicated system users (rootless)
- Containers restart automatically on boot or failure

**Characteristics**:
- Rootless containers (no root daemon)
- Systemd-integrated for reliability
- Declarative management via Ansible (no imperative Docker Compose files in production)
- Per-VM isolation (no cross-VM orchestration needed at this scale)

---

### 4. Application Layer

**Purpose**: Run user-facing and backend applications

#### Deployed Applications

| Application             | Purpose                                             | Host VM  | Data Disk  | Container Runtime        |
| ----------------------- | --------------------------------------------------- | -------- | ---------- | ------------------------ |
| **Plane**               | Project management (issues, sprints, docs)          | `office` | 50 GB ZFS  | Podman (multi-container) |
| **Leaf Wiki**           | Lightweight wiki/knowledge base                     | `office` | —          | Podman                   |
| **Paperless NGX**       | Document management (scan, tag, search)             | `office` | 100 GB ZFS | Podman (multi-container) |
| **Immich**              | Photo/video management (Google Photos alternative)  | `media`  | 1 TB ZFS   | Podman (multi-container) |
| **Pi-hole**             | DNS sinkhole, DHCP server, network-wide ad blocking | `pihole` | —          | Podman (LXC-style VM)    |
| **Nginx Proxy Manager** | Reverse proxy with web UI for all services          | `pihole` | —          | Podman                   |

#### Planned / In-Development Applications

| Application    | Purpose                                                     | Status                                                 |
| -------------- | ----------------------------------------------------------- | ------------------------------------------------------ |
| **Docmost**    | Document collaboration (role exists, data disk provisioned) | Config ready, not yet deployed via Ansible             |
| **Open WebUI** | AI chat interface for LLMs                                  | K8s manifests exist in `kubernetes/`, **not deployed** |

#### Application Isolation

- Each application runs as a dedicated system user (rootless Podman)
- Applications on different VMs are network-isolated (no cross-VM container communication without explicit proxy rules)
- All public-facing traffic routes through Nginx Proxy Manager (single entry point)
- Databases run on the dedicated `database` VM (separate from application VMs)

#### DNS and Routing

```
Internet / LAN
    │
    ▼
Pi-hole (DNS) ─── resolves *.lan.schwarzkopf.center
    │
    ▼
Nginx Proxy Manager (reverse proxy, port 80/443)
    │
    ├── plane.lan.schwarzkopf.center    → office VM:plane_port
    ├── wiki.lan.schwarzkopf.center     → office VM:leafwiki_port
    ├── paperless.lan.schwarzkopf.center → office VM:paperless_port
    ├── immich.lan.schwarzkopf.center   → media VM:immich_port
    ├── vault.lan.schwarzkopf.center    → pihole VM:8200
    ├── pihole.lan.schwarzkopf.center   → pihole VM:8443
    ├── npm.lan.schwarzkopf.center      → pihole VM:81
    ├── proxmox.lan.schwarzkopf.center  → homeserver:8006
    ├── pbs.lan.schwarzkopf.center      → backup VM:8007
    ├── fritz.lan.schwarzkopf.center    → fritzbox:80
    └── printer.lan.schwarzkopf.center  → printer:80
```

**See**:
- `ansible/roles/apps/` for application roles
- `ansible/playbooks/apps.yml` for deployment playbook
- `ansible/playbooks/proxy.yml` for NPM proxy host definitions

---

## Component Details

### OpenTofu Infrastructure Modules

**Module Hierarchy**:

```
tofu/
├── modules/
│   ├── virtual_machine/           # VM provisioning (CPU, RAM, disks, network)
│   └── cron_remote/               # Remote cron job scheduling
├── data/                          # Cloud-init templates, scripts
├── pihole/                        # Pi-hole DNS configuration
├── vms.tf                         # VM definitions (6 VMs)
├── pihole.tf                      # Pi-hole provisioning
├── proxmox.tf                     # Proxmox provider configuration
├── provider.tf                    # Provider configuration
└── variables.tf                   # Input variables
```

**Key Resources**:

1. **virtual_machine module**: Provisions complete VMs
   - Input: VM name, CPU, memory, disk sizes, network config
   - Output: VM ID, IP address
   - Supports cloud-init and additional data disks with backup tier assignment
   - Vault-backed SSH keys for automated access

2. **Pi-hole module**: Provisions Pi-hole DNS/DHCP server
   - Input: Password, Proxmox node
   - Output: DNS configuration

### Vault Secrets Management

**Vault** is deployed as a standalone service (not Kubernetes-integrated) and serves as the central secrets store for the homelab.

**Usage**:
- **OpenTofu**: Reads SSH authorized keys from Vault for VM provisioning
- **Ansible**: Stores and retrieves application secrets (database passwords, app secrets, API keys)
- **Applications**: Secrets are injected at deployment time (not runtime sidecar injection)

**Secret paths** (KV store, mount: `kv-apps`):
- `kv-apps/plane` — Plane secrets (db_password, secret_key, minio keys, etc.)
- `kv-apps/docmost` — Docmost secrets (app_secret, db_password)
- `kv-apps/immich` — Immich secrets
- `kv-apps/paperless` — Paperless secrets
- `kv-apps/ssh_authorized_key` — SSH public keys for VM access

**Access**: Via API at `https://vault.lan.schwarzkopf.center` (proxied through NPM to pihole VM, port 8200)

**Characteristics**:
- Centralized secrets store
- Versioned secret data (rollback capability)
- Audit logging of all secret access
- API-driven (used by both OpenTofu and Ansible)

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md) for security model rationale

### Database Layer

**PostgreSQL** runs as Podman containers on the dedicated `database` VM:

| Instance               | Image                              | Port | Data Disk | Purpose                             |
| ---------------------- | ---------------------------------- | ---- | --------- | ----------------------------------- |
| `postgres`             | postgres:17.6                      | 5432 | 20 GB ZFS | General application databases       |
| `postgres-vectorchord` | immich-app/postgres:14-vectorchord | 5433 | 10 GB ZFS | Immich (pgvector for ML embeddings) |

Each application gets its own database and user, provisioned by Ansible.

**See**: `ansible/playbooks/databases.yml` for database definitions

### Nginx Proxy Manager

Nginx Proxy Manager (NPM) runs as a Podman container on the `pihole` VM and serves as the single reverse proxy entry point for all services:

- Web UI at `https://npm.lan.schwarzkopf.center`
- SSL/TLS termination (Let's Encrypt via NPM)
- Domain-based routing to all applications and services
- Configured programmatically via Ansible (API-driven)

---

## Data Flow

### Application Request Flow

```
User Request (browser/app)
    │
    ▼
DNS Resolution (Pi-hole, *.lan.schwarzkopf.center)
    │
    ▼
Nginx Proxy Manager (port 80/443, TLS termination)
    │
    ├── Application VMs (office: Plane, Leaf Wiki, Paperless)
    │       │
    │       ▼
    │   Podman Container (rootless, systemd-managed)
    │       │
    │       ▼
    │   ZFS Data Disk (mounted via Proxmox)
    │
    ├── Application VMs (media: Immich)
    │       │
    │       ▼
    │   Podman Containers (server, microservices, ML)
    │       │
    │       ▼
    │   ZFS Data Disk (immich, 1 TB)
    │
    └── Database VM
            │
            ▼
        PostgreSQL (Podman, port 5432/5433)
            │
            ▼
        ZFS Data Disk (postgres/vectorchord)
```

### Secret Access Flow

```
Ansible Run / OpenTofu Apply
    │
    ▼
Vault API (https://vault.lan.schwarzkopf.center)
    │
    ▼
Authenticate (token-based)
    │
    ▼
Read secret from kv-apps/<path>
    │
    ▼
Secret data returned to Ansible/OpenTofu
    │
    ▼
Used for: VM provisioning, DB user creation, container env vars
    │
    ▼
Vault Audit Log (access recorded)
```

### Deployment Flow

```
Git Commit (code change)
    │
    ▼
Manual Ansible run (or CI trigger)
    │
    ▼
Ansible connects to target VM (SSH)
    │
    ├── Fetches secrets from Vault
    ├── Pulls container images
    ├── Generates systemd unit files
    ├── Starts/stops Podman containers
    └── Configures NPM proxy hosts
    │
    ▼
Application is updated and serving traffic
```

### Backup Flow

**See**: [BACKUP.md](operations/BACKUP.md#backup-flow) for detailed backup flow diagram and explanation

---

## Design Principles

### 1. Infrastructure as Code

**Principle**: All infrastructure is defined in code, version-controlled, and reproducible.

**Implementation**:
- OpenTofu for VM and network provisioning
- Ansible playbooks for configuration and deployment
- Packer for VM image building
- Git for version control

**Benefits**:
- Reproducible deployments
- Audit trail of changes
- Easy rollback
- Collaboration and review

### 2. Immutable Infrastructure

**Principle**: Infrastructure components are replaced, not modified.

**Implementation**:
- Packer-built VM images (immutable base OS)
- Container images (immutable application packages)
- Automated VM rebuilds via OpenTofu
- Configuration via cloud-init (immutable provisioning)

**Benefits**:
- Eliminates configuration drift
- Faster recovery from failures
- Easier to test changes
- Better security posture

### 3. Security by Default

**Principle**: Security is built-in, not added later.

**Implementation**:
- Vault for all secrets (no plaintext secrets in code)
- Rootless Podman containers (no root daemon)
- TLS for all public-facing services
- Network isolation between VMs
- SSH key-based access (no passwords)
- Principle of least privilege for service accounts

**Benefits**:
- Reduced security risk
- Compliance-ready
- Easier incident response
- Better audit trails

### 4. Declarative Configuration

**Principle**: Describe desired state, not steps to achieve it.

**Implementation**:
- OpenTofu HCL (declarative infrastructure)
- Ansible playbooks (declarative desired state)
- Ansible idempotency (safe to re-run)

**Benefits**:
- Easier to understand
- Automatic drift detection
- Self-healing (re-run playbooks)
- Easier to test

### 5. Modularity and Reusability

**Principle**: Components are modular, reusable, and composable.

**Implementation**:
- OpenTofu modules for infrastructure
- Ansible roles for applications
- Shared role dependencies (vault, podman, os_debian, postgres)

**Benefits**:
- Easier to maintain
- Easier to extend
- Easier to test
- Consistent across applications

### 6. Observability

**Principle**: Systems are observable and debuggable.

**Implementation**:
- Application logging (stdout/stderr via Podman/journald)
- Vault audit logging
- Proxmox monitoring (CPU, RAM, disk, network per VM)
- Health checks on containers (systemd)

**Benefits**:
- Faster incident response
- Better understanding of system behavior
- Easier troubleshooting

### 7. Separation of Concerns

**Principle**: Each layer has distinct responsibilities.

**Implementation**:
- Dedicated VMs per workload type (database, media, office, backup)
- Dedicated system users per application (rootless Podman)
- Clear data flow between layers
- No cross-VM dependencies (except database access)

**Benefits**:
- Reduced blast radius
- Easier maintenance
- Clearer troubleshooting

---

## Performance Characteristics

### Resource Allocation

**Physical Host** (`homeserver`):
- CPU: Shared across all VMs (oversubscription possible)
- RAM: Distributed to VMs with overhead
- Storage: ZFS with compression (expected 2-5x reduction)

**VM Performance**:
- `database`: 4 CPU / 8 GB — adequate for multi-tenant PostgreSQL
- `office`: 4 CPU / 8 GB — adequate for Plane + Paperless + Leaf Wiki
- `media`: 2 CPU / 4 GB — adequate for Immich (GPU passthrough for ML)
- `backup`: 2 CPU / 4 GB — adequate for Proxmox Backup Server
- `games`: 4 CPU / 8 GB — adequate for game servers
- `utility`: 2 CPU / 2 GB — lightweight services

### Network

**Bandwidth**:
- Current: 1 Gbps internal network
- Bottleneck: Disk I/O for backup and large file operations
- All VM traffic traverses Proxmox virtual bridge

**Latency**:
- VM-to-VM: <1ms (same hypervisor)
- VM-to-Database: <1ms
- VM-to-Storage: Depends on ZFS pool (SSD vs HDD)
- External: Depends on ISP and WAN conditions

### Storage

**ZFS Pools**:
- `zfs-nas`: Primary data pool (application data disks)
- `vm-os-pool`: OS disks for VMs
- `zfs-longhorn`: Backup config storage (small, 1 GB)

**Compression**: ZFS compression enabled on data pools (lz4 or similar)

---

## Scalability Considerations

### Current Scale

The homelab operates at a modest scale suitable for a home environment:

- **1 physical host** (Proxmox single node)
- **7 VMs** (games, utility, database, backup, media, office, pihole)
- **2 PostgreSQL instances** (standard + vectorchord)
- **5 containerized applications** (Plane, Leaf Wiki, Paperless, Immich, Pi-hole)
- **Total data**: ~2.3 TB provisioned across data disks

### Horizontal Scaling

**VMs**:
- Current: 7 VMs on 1 Proxmox host
- Future: Add VMs via OpenTofu module (add entry to `local.virtual_machines`)
- Limit: Physical host resources (CPU, RAM, storage)

**Applications**:
- Current: Single-instance per VM (appropriate for home use)
- Scaling: Add more application VMs for new services
- Each new service follows the same pattern: OpenTofu VM → Ansible deploy → NPM proxy

### Vertical Scaling

**VM Resources**:
- CPU: 2-4 cores per VM (configurable in `vms.tf`)
- Memory: 2-8 GB per VM (configurable in `vms.tf`)
- Storage: 10 GB - 1.5 TB per data disk

**Database**:
- Current: Single PostgreSQL VM
- Scaling: Increase VM resources (CPU, RAM) or add read replicas

**See**: `tofu/vms.tf` for current resource allocations

### Future Directions

The following are **not currently deployed** but are under consideration for future expansion:

- **Kubernetes cluster**: The `kubernetes/` directory contains example manifests and bootstrap configurations (ArgoCD, MetalLB, Longhorn, Vault integration, Cilium). These are **templates only** — no Kubernetes cluster exists. If the homelab grows beyond ~10 VMs or requires advanced orchestration, Kubernetes would be the next logical step.
- **Multi-node Proxmox cluster**: Currently single-node. Adding a second Proxmox host would enable HA and live migration.
- **Off-site backup**: Currently on-site only (Proxmox Backup Server on `backup` VM). AWS S3 replication is a future consideration.

---

## Security Architecture

### Defense in Depth

**Layer 1: Physical / Host Security**
- Proxmox host access control
- SSH key-based authentication (no passwords)
- API token-based automation

**Layer 2: Network Security**
- VM-level network isolation (separate virtual networks if needed)
- Pi-hole DNS filtering (blocks known malicious domains)
- Nginx Proxy Manager as single entry point (TLS termination)
- Firewall rules on Proxmox bridge

**Layer 3: Access Control**
- SSH key-based access to all VMs
- Rootless Podman (containers run as unprivileged users)
- No direct container access from outside (proxied through NPM)
- Per-application system users

**Layer 4: Secrets Management**
- Vault for all secrets (no plaintext secrets in Git)
- Automatic secret retrieval at deployment time
- Vault audit logging
- Secret version history for rollback

**Layer 5: Application Security**
- Container images from trusted registries (Docker Hub, GitHub Container Registry)
- Resource limits on containers
- Immutable base OS (Packer-built images)
- Regular updates via Ansible playbook re-runs

**Layer 6: Monitoring & Audit**
- Vault audit log
- Proxmox event log
- Application-level logging (journald)

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md) for detailed security model rationale and design

### Threat Model

**Threats Addressed**:

1. **Unauthorized Access**
   - Mitigation: SSH keys, Vault API tokens, NPM authentication
   - Detection: Vault audit logging, SSH log monitoring

2. **Data Breach**
   - Mitigation: Encryption in transit (TLS), Vault for secrets
   - Detection: Audit logging

3. **Configuration Drift**
   - Mitigation: Infrastructure as Code (OpenTofu, Ansible)
   - Detection: Re-run playbooks to reconcile

4. **Insider Threat**
   - Mitigation: RBAC-limited Vault tokens, per-application service users
   - Detection: Vault audit logging

5. **Supply Chain Attack**
   - Mitigation: Container images from known registries, pinned versions
   - Detection: Manual review of image updates

---

## Disaster Recovery

### Recovery Objectives

**See**: [OPERATIONS.md](OPERATIONS.md#recovery-objectives) for detailed RPO/RTO table and recovery procedures

### Backup Strategy

**Tiered Approach**:
- Different backup frequencies for different data types
- Cost-optimized storage allocation
- Automated backup scheduling via Proxmox Backup Server

**Backup Locations**:
- Primary: On-site Proxmox Backup Server (`backup` VM, 1.5 TB data disk)
- Secondary: Off-site replication into AWS S3 (future)

**Backup Tiers**:

| Tier | Data                 | Frequency | Retention  |
| ---- | -------------------- | --------- | ---------- |
| 0    | Backup server config | Real-time | N/A        |
| 1    | Databases (postgres) | Daily     | 30 days    |
| 2    | Application data     | Daily     | 14 days    |
| 3    | (reserved)           | —         | —          |
| 4    | ROM archives         | On-change | Indefinite |

**See**: 
- [ADR-005](decisions/ADR-005-tiered-backup-strategy.md) for backup strategy rationale
- [OPERATIONS.md](OPERATIONS.md#disaster-recovery) for recovery procedures and runbooks

### High Availability

**Current State**:
- Single Proxmox host (no HA clustering)
- Single PostgreSQL instance (no replication)
- Single instance per application (no load balancing)
- Backup: Proxmox Backup Server for VM-level recovery
- Recovery: Manual (restore VM from PBS backup)

**Future improvements**:
- Multi-node Proxmox cluster for VM HA
- PostgreSQL streaming replication
- Application multi-instance with NPM load balancing

**See**: [OPERATIONS.md](OPERATIONS.md#disaster-recovery) for disaster recovery procedures and runbooks

---

## References

### Architecture Decision Records
- [ADR-001: Platform Choice (OpenTofu vs Terraform)](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md)
- [ADR-002: Kubernetes Approach (Talos Linux)](decisions/ADR-002-kubernetes-approach-talos-linux.md) *(Future direction — not currently deployed)*
- [ADR-003: Storage Strategy (Longhorn)](decisions/ADR-003-storage-strategy-longhorn.md) *(Future direction — not currently deployed)*
- [ADR-004: Security Model (Vault + RBAC)](decisions/ADR-004-security-model-vault-rbac.md)
- [ADR-005: Tiered Backup Strategy](decisions/ADR-005-tiered-backup-strategy.md)

### External Documentation
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Podman Documentation](https://docs.podman.io/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Pi-hole Documentation](https://docs.pi-hole.net/)

---

**Last Updated**: May 2026  
**Status**: Active — reflects actual deployed state  
**Maintainer**: Eduard