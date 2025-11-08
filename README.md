# Homelab

A personal infrastructure project built with OpenTofu, Proxmox, and Kubernetes. This homelab provides a complete, self-hosted environment for running containerized applications with high availability, automated backups, and security-first design.

## About This Project

This is my personal homelab infrastructure - a learning project and practical environment for exploring modern infrastructure practices.
It demonstrates how to build a production-grade, self-hosted platform using Infrastructure as Code, containerization, and cloud-native technologies.

**Why it exists**: I created this to have full control over my infrastructure, learn Kubernetes and infrastructure automation at scale, and build a reliable platform for running personal applications and services.

**For others**: If you're building your own homelab or learning infrastructure concepts, feel free to use this as a reference, adapt it for your needs, or learn from the architectural decisions documented in [docs/decisions/](docs/decisions/). Questions and discussions are welcome—this project is meant to be shared and learned from.

## What This Is

A fully automated infrastructure stack that manages:
- **Virtualization**: Proxmox VE hypervisor with KVM/QEMU
- **Container Orchestration**: Multi-node Kubernetes cluster (Talos Linux)
- **Storage**: Distributed storage with Longhorn and ZFS
- **Networking**: Service mesh with Cilium, load balancing with MetalLB
- **Secrets Management**: HashiCorp Vault for centralized credential management
- **Deployment**: GitOps-based application deployment with ArgoCD
- **Backup & Recovery**: Tiered backup strategy with defined RPO/RTO targets

## Key Technologies

| Layer                      | Technology      |
| -------------------------- | --------------- |
| **Infrastructure as Code** | OpenTofu        |
| **Hypervisor**             | Proxmox VE      |
| **Kubernetes OS**          | Talos Linux     |
| **Secrets**                | HashiCorp Vault |
| **GitOps**                 | ArgoCD          |

## Diagram

![Network Diagram](docs/img/homelab.drawio.svg)

## Quick Start

### Prerequisites
- OpenTofu, Packer, kubectl
- Proxmox VE environment
- Access to the infrastructure

### Setup

```bash
# 1. Build VM images
cd packer/linux
packer init .
packer build -var-file=ubuntu-24042.pkrvars.hcl .

# 2. Provision infrastructure
cd tofu/infrastructure
tofu init
tofu plan
tofu apply

# 3. Bootstrap Kubernetes
cd kubernetes/bootstrap
kubectl apply -k .

# 4. Deploy applications
# Applications are managed via ArgoCD (see kubernetes/apps/)
```

See [packer/README.md](packer/README.md) for detailed image building instructions.

## Project Structure

```
homelab/
├── docs/                   # Documentation and architecture decisions
├── kubernetes/             # Kubernetes manifests and applications
│   ├── apps/               # Application deployments
│   └── bootstrap/          # Cluster bootstrap (ArgoCD, Vault, Longhorn, MetalLB)
├── packer/                 # VM image building
├── tofu/                   # Infrastructure as Code
│   ├── infrastructure/     # Core infrastructure (Proxmox, VMs, networking)
│   └── services/           # Service configurations (Vault, Postgres, Nginx)
└── README.md               # This file
```

## Contributing & Community

This is a personal project, but I welcome questions, discussions, and ideas from others building similar infrastructure. If you're:
- **Learning infrastructure concepts** - explore the code and architectural decisions
- **Building your own homelab** - adapt and use what works for your setup
- **Curious about specific decisions** - check [docs/decisions/](docs/decisions/) for the reasoning behind key choices

Feel free to open discussions or ask questions about how things are implemented.

## License

Licensed under [GPL-3.0](LICENSE).
