# Homelab Architecture Documentation

> Comprehensive technical architecture of the homelab infrastructure, including component relationships, data flow, design decisions, and operational characteristics.

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

The homelab infrastructure is organized into **7 distinct layers**, each with specific responsibilities:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  (Paperless NGX, Open WebUI, Custom Applications)           │
├─────────────────────────────────────────────────────────────┤
│                    Orchestration Layer                      │
│  (ArgoCD, Ingress-NGINX, MetalLB, Service Mesh)             │
├─────────────────────────────────────────────────────────────┤
│                    Kubernetes Layer                         │
│  (Talos Linux, Cilium, Kubelet, API Server)                 │
├─────────────────────────────────────────────────────────────┤
│                    Storage Layer                            │
│  (Longhorn, ZFS, Persistent Volumes)                        │
├─────────────────────────────────────────────────────────────┤
│                    Security Layer                           │
│  (Vault, RBAC, Network Policies, Audit Logging)             │
├─────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                     │
│  (Proxmox VE, OpenTofu, Networking, Storage Pools)          │
├─────────────────────────────────────────────────────────────┤
│                    Virtualization Layer                     │
│  (KVM, QEMU, Virtual Machines, Virtual Networks)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture Layers

### 1. Virtualization Layer

**Purpose**: Provide virtual compute, storage, and networking resources

**Components**:
- **Proxmox VE**: Hypervisor and cluster management
- **KVM/QEMU**: Virtual machine execution
- **Virtual Networks**: Isolated network segments
- **Storage Pools**: ZFS-based storage for VMs and backups

**Characteristics**:
- Bare-metal hypervisor for maximum performance
- Cluster-aware for high availability
- Native ZFS support for snapshots and replication
- Web UI and API for management

**Scaling**: Supports 2-10+ physical nodes

**See**: [ADR-001](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md) for Proxmox selection rationale

---

### 2. Infrastructure Layer

**Purpose**: Automate infrastructure provisioning and management

**Components**:
- **OpenTofu**: Infrastructure as Code tool
- **Packer**: VM image building and templating
- **Terraform Providers**: Proxmox, Kubernetes, Vault providers
- **State Management**: Remote state for infrastructure tracking

**Key Modules**:
- `proxmox/`: Proxmox cluster configuration
- `vms/kubernetes/`: Kubernetes cluster VMs
- `vms/ollama/`: ML model serving VM
- `vms/postgres/`: Database VM
- `vms/pbs/`: Backup server VM
- `vms/sandbox/`: Development/testing VM

**Characteristics**:
- Declarative infrastructure definition
- Version-controlled configuration
- Modular, reusable components
- Automatic drift detection

**Scaling**: Easily add new VMs and services by adding modules

**See**: 
- [ADR-001](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md) for OpenTofu vs Terraform
- `tofu/infrastructure/` for implementation

---

### 3. Security Layer

**Purpose**: Protect data, control access, and maintain audit trails

**Components**:
- **HashiCorp Vault**: Centralized secrets management
- **Kubernetes RBAC**: Role-based access control
- **Network Policies**: Kubernetes network segmentation
- **Audit Logging**: Complete access audit trail
- **TLS**: Encrypted communication

**Security Mechanisms**:

1. **Secrets Management**
   - Vault stores all sensitive data (passwords, API keys, certificates)
   - Automatic secret injection into pods
   - Centralized secret storage and access control

2. **Access Control**
   - Kubernetes RBAC for API access
   - Service account binding to roles
   - Namespace isolation
   - Network policies for traffic control

3. **Encryption**
   - AES-256 encryption at rest (Vault)
   - TLS 1.3 for in-transit encryption

4. **Audit Logging**
   - Kubernetes API audit logs
   - Application-level logging
   - Centralized log aggregation

**Characteristics**:
- Defense in depth with multiple layers
- Principle of least privilege
- Centralized secrets management
- Secure secret injection

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md) for security model rationale

---

### 4. Storage Layer

**Purpose**: Provide persistent, reliable storage for applications

**Components**:
- **Longhorn**: Kubernetes-native distributed storage
- **ZFS**: Filesystem and volume management
- **Persistent Volumes**: Kubernetes storage abstraction
- **Snapshots**: Point-in-time recovery capability
- **Backup Storage**: Proxmox Backup Server pools

**Storage Architecture**:

```
Kubernetes Pods
    ↓
PersistentVolumeClaims (PVC)
    ↓
Longhorn StorageClass
    ↓
Longhorn Volumes (distributed across nodes)
    ↓
ZFS Datasets (on Proxmox storage pools)
    ↓
Physical Disks
```

**Backup Integration**:
- Longhorn snapshots for point-in-time recovery
- Tiered backup strategy (Tier 1-4)
- Proxmox Backup Server for VM backups
- Incremental backup support

**Characteristics**:
- Kubernetes-native (no external dependencies)
- Distributed replication for fault tolerance
- Simple operational model
- Web UI for management

**Scaling**: Add storage nodes to increase capacity and performance

**See**: [ADR-003](decisions/ADR-003-storage-strategy-longhorn.md) for storage strategy rationale

---

### 5. Kubernetes Layer

**Purpose**: Orchestrate containerized applications

**Components**:
- **Talos Linux**: Immutable Kubernetes OS
- **Kubernetes API Server**: Control plane
- **Kubelet**: Node agent
- **Cilium**: Network plugin and service mesh
- **CoreDNS**: Service discovery
- **etcd**: Distributed configuration store

**Cluster Architecture**:

```
Control Plane (3 nodes)
├── API Server
├── Scheduler
├── Controller Manager
└── etcd

Worker Nodes (2-6 nodes)
├── Kubelet
├── Container Runtime (containerd)
└── Cilium Agent
```

**Kubernetes Features**:
- Multi-node cluster for high availability
- Automatic pod scheduling and scaling
- Service discovery and load balancing
- Rolling updates and rollbacks
- Resource quotas and limits
- Network policies for security

**Talos Linux Specifics**:
- Immutable OS (no SSH, no shell)
- API-driven configuration
- Atomic updates with automatic rollback
- Minimal attack surface
- Optimized for Kubernetes

**Characteristics**:
- Production-grade Kubernetes
- Highly available control plane
- Automatic node recovery
- Self-healing capabilities

**Scaling**: Add worker nodes to increase capacity

**See**: [ADR-002](decisions/ADR-002-kubernetes-approach-talos-linux.md) for Kubernetes approach rationale

---

### 6. Orchestration Layer

**Purpose**: Manage application deployment and traffic routing

**Components**:
- **ArgoCD**: GitOps continuous delivery
- **Ingress-NGINX**: HTTP ingress controller
- **MetalLB**: Load balancer for bare-metal
- **Cilium**: Advanced networking and service mesh
- **Kustomize**: Kubernetes manifest templating

**Application Deployment Flow**:

```
Git Repository (source of truth)
    ↓
ArgoCD (watches Git)
    ↓
Kubernetes API (applies manifests)
    ↓
Kubelet (schedules pods)
    ↓
Container Runtime (runs containers)
```

**Traffic Flow**:

```
External Traffic
    ↓
MetalLB (assigns IP)
    ↓
Ingress-NGINX (routes HTTP/HTTPS)
    ↓
Service (load balances)
    ↓
Pods (application instances)
```

**GitOps Workflow**:
1. Developer commits to Git
2. ArgoCD detects changes
3. ArgoCD applies manifests to cluster
4. Kubernetes reconciles desired state
5. Applications are updated automatically

**Characteristics**:
- Declarative application management
- Git as single source of truth
- Automatic synchronization
- Rollback capability via Git history
- Audit trail of all changes

**See**: `kubernetes/bootstrap/` for implementation

---

### 7. Application Layer

**Purpose**: Run user-facing and backend applications

**Application Patterns**:
- Stateless services (horizontally scalable)
- Stateful services (with persistent storage)
- Batch jobs (scheduled or on-demand)
- Daemon sets (one per node)

**See**: `kubernetes/apps/` for application manifests

---

## Component Details

### OpenTofu Infrastructure Modules

**Module Hierarchy**:

```
tofu/infrastructure/
├── modules/
│   ├── proxmox_automation_user/    # Proxmox API user
│   ├── data_disk_vm/               # Data disk provisioning
│   └── server/                     # VM provisioning
├── proxmox/                        # Proxmox cluster config
├── vms/                            # Virtual Machines
└── services/                       # Service configurations
```

**Key Modules**:

1. **data_disk_vm**: Provisions data disks with backup tier assignment
   - Input: VM name, size, backup tier (1-4)
   - Output: Disk ID, pool name
   - Supports tiered backup strategy

2. **server**: Provisions complete VMs
   - Input: VM name, CPU, memory, disk, network
   - Output: VM ID, IP address
   - Supports cloud-init provisioning

3. **proxmox_automation_user**: Creates API users
   - Input: Username, permissions
   - Output: API token
   - Enables IaC automation

### Kubernetes Bootstrap Components

**Bootstrap Order**:

```
1. Namespace creation
2. RBAC setup
3. Storage (Longhorn)
4. Networking (MetalLB, Cilium)
5. Ingress (NGINX)
6. Secrets (Vault)
7. GitOps (ArgoCD)
8. Applications
```

**Key Resources**:

1. **Longhorn**: Distributed storage
   - StorageClass for dynamic provisioning
   - Snapshot support
   - Replication policies

2. **MetalLB**: Load balancer
   - IP pool configuration
   - BGP or L2 mode
   - Service LoadBalancer support

3. **Ingress-NGINX**: HTTP routing
   - TLS termination
   - Path-based routing
   - Rate limiting

4. **Vault**: Secrets management
   - Kubernetes auth method
   - Secret injection
   - Audit logging

5. **ArgoCD**: GitOps deployment
   - Application definitions
   - Automatic synchronization
   - Health monitoring

---

## Data Flow

### Application Request Flow

```
User Request
    ↓
DNS Resolution (CoreDNS)
    ↓
MetalLB (LoadBalancer IP)
    ↓
Ingress-NGINX (HTTP routing)
    ↓
Service (port mapping)
    ↓
Pod (application container)
    ↓
Persistent Volume (if needed)
    ↓
Longhorn (distributed storage)
    ↓
ZFS (physical storage)
```

### Secret Access Flow

```
Pod Startup
    ↓
Vault Agent Init Container
    ↓
Kubernetes Auth (service account)
    ↓
Vault (authenticate pod)
    ↓
Vault (retrieve secret)
    ↓
Secret Injection (into pod)
    ↓
Application (uses secret)
    ↓
Vault Audit Log (access recorded)
```

### Backup Flow

**See**: [BACKUP.md](operations/BACKUP.md#backup-flow) for detailed backup flow diagram and explanation

### Deployment Flow

```
Git Commit
    ↓
Git Push
    ↓
ArgoCD Webhook (detects change)
    ↓
ArgoCD (fetches manifests)
    ↓
Kustomize (renders manifests)
    ↓
Kubernetes API (applies manifests)
    ↓
Kubelet (schedules pods)
    ↓
Container Runtime (pulls image, runs container)
    ↓
Application (starts)
    ↓
Vault Agent (injects secrets)
    ↓
Application (ready to serve)
```

---

## Design Principles

### 1. Infrastructure as Code

**Principle**: All infrastructure is defined in code, version-controlled, and reproducible.

**Implementation**:
- OpenTofu for VM and network provisioning
- Kubernetes manifests for application deployment
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
- Talos Linux (immutable OS)
- Container images (immutable application packages)
- Kubernetes rolling updates
- Automated VM rebuilds

**Benefits**:
- Eliminates configuration drift
- Faster recovery from failures
- Easier to test changes
- Better security posture

### 3. Security by Default

**Principle**: Security is built-in, not added later.

**Implementation**:
- Vault for all secrets
- RBAC for access control
- Network policies for segmentation
- Encryption at rest and in transit

**Benefits**:
- Reduced security risk
- Compliance-ready
- Easier incident response
- Better audit trails

### 4. Declarative Configuration

**Principle**: Describe desired state, not steps to achieve it.

**Implementation**:
- Kubernetes manifests (declarative)
- OpenTofu HCL (declarative)
- ArgoCD (declarative deployment)
- Kustomize (declarative templating)

**Benefits**:
- Easier to understand
- Automatic reconciliation
- Self-healing
- Easier to test

### 5. Modularity and Reusability

**Principle**: Components are modular, reusable, and composable.

**Implementation**:
- OpenTofu modules for infrastructure
- Kubernetes Helm charts for applications
- Kustomize overlays for configuration
- Microservices architecture

**Benefits**:
- Easier to maintain
- Easier to extend
- Easier to test
- Easier to scale

### 6. Observability

**Principle**: Systems are observable and debuggable.

**Implementation**:
- Comprehensive logging
- Metrics collection
- Distributed tracing
- Health checks
- Audit logging

**Benefits**:
- Faster incident response
- Better understanding of system behavior
- Easier troubleshooting
- Compliance support

### 7. High Availability

**Principle**: Systems are designed to tolerate failures.

**Implementation**:
- Single control plane + single worker node Kubernetes cluster
- Distributed storage with replication
- Automatic failover
- Health-based pod eviction
- Backup and recovery

**Benefits**:
- Reduced downtime
- Better user experience
- Easier maintenance
- Disaster recovery capability

---

## Scalability Considerations

### Horizontal Scaling

**Kubernetes Cluster**:
- Current: 1 control plane + 1 worker node
- Future: Can scale to 3 control plane + 10+ worker nodes
- Scaling: Add new VMs via OpenTofu

**Storage**:
- Current: 1 node with Longhorn
- Future: Can scale to 10+ nodes with Longhorn
- Scaling: Add new nodes, Longhorn auto-rebalances

**Applications**:
- Stateless services: Scale to 10+ replicas
- Stateful services: Limited by storage performance
- Batch jobs: Scale with available resources

### Vertical Scaling

**Node Resources**:
- CPU: 4-16 cores per node
- Memory: 8-64 GB per node
- Storage: 100 GB - 2 TB per node

**Cluster Limits**:
- etcd: ~5000 nodes (Kubernetes limit)
- API server: ~5000 requests/second
- Kubelet: ~110 pods per node

### Storage Scaling

**Longhorn**:
- Replication factor: 1-3
- Volume size: 1 GB - 2 TB
- Total capacity: Limited by physical storage

**ZFS**:
- Pool size: Limited by physical disks
- Compression: 2-5x reduction
- Snapshots: Minimal overhead

### Network Scaling

**Bandwidth**:
- Current: 1 Gbps network
- Bottleneck: Network bandwidth for replication
- Upgrade: 10 Gbps for larger deployments

**Latency**:
- Pod-to-pod: <5ms (same network)
- Pod-to-storage: 10-50ms (network + storage)
- Pod-to-external: Depends on external network

---

## Security Architecture

### Defense in Depth

**Layer 1: Physical Security**
- Proxmox host security
- Network isolation
- Physical access control

**Layer 2: Network Security**
- Network policies (Cilium)
- Firewall rules
- Service mesh (Cilium)
- TLS for all communication

**Layer 3: Access Control**
- Kubernetes RBAC
- Service account binding
- Network policies
- Pod security policies

**Layer 4: Secrets Management**
- Vault for all secrets
- Automatic injection
- Audit logging
- Secret rotation

**Layer 5: Application Security**
- Container image scanning
- Resource limits
- Security contexts
- Pod security standards

**Layer 6: Monitoring & Audit**
- Comprehensive logging
- Audit logging
- Intrusion detection
- Compliance monitoring

**See**: [ADR-004](decisions/ADR-004-security-model-vault-rbac.md) for detailed security model rationale and design

### Threat Model

**Threats Addressed**:

1. **Unauthorized Access**
   - Mitigation: RBAC, network policies, authentication
   - Detection: Audit logging

2. **Data Breach**
   - Mitigation: Encryption at rest and in transit
   - Detection: Audit logging, intrusion detection

3. **Configuration Drift**
   - Mitigation: Immutable infrastructure, IaC
   - Detection: Continuous reconciliation

4. **Insider Threat**
   - Mitigation: RBAC, audit logging, separation of duties
   - Detection: Audit logging, anomaly detection

5. **Supply Chain Attack**
   - Mitigation: Image scanning, signed images
   - Detection: Image verification, vulnerability scanning

---

## Disaster Recovery

### Recovery Objectives

**See**: [OPERATIONS.md](OPERATIONS.md#recovery-objectives) for detailed RPO/RTO table and recovery procedures

### Backup Strategy

**Tiered Approach**:
- Different backup frequencies for different data types
- Cost-optimized storage allocation
- Compliance-aligned retention policies
- Automated backup scheduling

**Backup Locations**:
- Primary: On-site Proxmox Backup Server
- Secondary: Off-site replication into AWS S3 (future)

**See**: 
- [ADR-005](decisions/ADR-005-tiered-backup-strategy.md) for backup strategy rationale
- [OPERATIONS.md](OPERATIONS.md#disaster-recovery) for recovery procedures and runbooks

### High Availability

**Control Plane**:
- Single control plane node (sufficient for current homelab scale)
- Backup and recovery procedures
- API access via kubectl

**Worker Nodes**:
- Single worker node (sufficient for current homelab scale)
- Automatic pod rescheduling
- Node health monitoring

**Storage**:
- Longhorn replication (2-3 replicas)
- Automatic failover
- Data redundancy
- Snapshot recovery

**Applications**:
- Multiple pod replicas
- Pod disruption budgets
- Graceful shutdown
- Health checks

**See**: [OPERATIONS.md](OPERATIONS.md#disaster-recovery) for disaster recovery procedures and runbooks

---

## References

### Architecture Decision Records
- [ADR-001: Platform Choice (OpenTofu vs Terraform)](decisions/ADR-001-platform-choice-opentofu-vs-terraform.md)
- [ADR-002: Kubernetes Approach (Talos Linux)](decisions/ADR-002-kubernetes-approach-talos-linux.md)
- [ADR-003: Storage Strategy (Longhorn)](decisions/ADR-003-storage-strategy-longhorn.md)
- [ADR-004: Security Model (Vault + RBAC)](decisions/ADR-004-security-model-vault-rbac.md)
- [ADR-005: Tiered Backup Strategy](decisions/ADR-005-tiered-backup-strategy.md)

### External Documentation
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Talos Linux Documentation](https://www.talos.dev/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [ArgoCD Documentation](https://argoproj.github.io/cd/)

---

**Last Updated**: November 2025  
**Status**: Active  
**Maintainer**: Eduard
