# Homelab

A personal infrastructure project built with OpenTofu, Packer, Proxmox, and Ansible. This homelab provides a complete, self-hosted environment for running containerized applications with automation, backups, and security-first design.

## About This Project

This is my personal homelab infrastructure - a learning project and practical environment for exploring modern infrastructure practices.
It demonstrates how to build a self-hosted platform using Infrastructure as Code, containerization, and automation.

**Why it exists**: I created this to have full control over my infrastructure, learn infrastructure automation at scale, and build a reliable platform for running personal applications and services.

**For others**: If you're building your own homelab or learning infrastructure concepts, feel free to use this as a reference, adapt it for your needs, or learn from the architectural decisions documented in [docs/decisions/](docs/decisions/). Questions and discussions are welcome—this project is meant to be shared and learned from.

## Tech Stack

| Layer                      | Technology |
| -------------------------- | ---------- |
| **Configuration**          | Ansible    |
| **Containers**             | Podman     |
| **Infrastructure as Code** | OpenTofu   |
| **VM Image Building**      | Packer     |
| **Hypervisor**             | Proxmox VE |
| **VMs / Base OS**          | Debian     |

## What This Is

A fully automated infrastructure stack that manages:
- **Virtualization**: Proxmox VE hypervisor with KVM/QEMU
- **Containers**: Podman-based application deployment via Ansible
- **Infrastructure**: OpenTofu for provisioning VMs and resources
- **VM Images**: Packer for building base images
- **Automation**: Ansible playbooks for application deployment

## Diagram

```mermaid
graph TD
    User["User / Browser"]

    subgraph Proxmox["Proxmox VE"]
        subgraph VM_Layer["Debian VMs (Ansible + Podman)"]
            NPM["Nginx Proxy Manager\n(utility VM)"]
            Office["Office VM\nDocmost · Plane · Paperless"]
            Media["Media VM\nImmich · Retro Games"]
            DB["Database VM\nPostgreSQL · pgvector"]
            Games["Games VM"]
        end

        subgraph K8s_Layer["Kubernetes — Talos Linux (in progress)"]
            MetalLB["MetalLB\n(LoadBalancer)"]
            Nginx["Ingress-NGINX"]
            ArgoCD["ArgoCD\n(GitOps)"]
            OpenWebUI["Open-WebUI"]
            Longhorn["Longhorn\n(Storage)"]
        end

        subgraph Storage["Storage"]
            ZFS["ZFS\n(NAS · OS disks)"]
            PBS["Proxmox Backup Server"]
        end
    end

    Git["Git Repository"]
    Vault["HashiCorp Vault\n(Secrets)"]
    PiHole["PiHole\n(DNS)"]

    User -->|DNS lookup| PiHole
    PiHole -->|VM apps| NPM
    PiHole -->|K8s apps| MetalLB

    NPM --> Office
    NPM --> Media
    NPM --> Games

    Office --> DB
    Media --> DB

    MetalLB --> Nginx
    Nginx --> OpenWebUI

    Git -->|watches| ArgoCD
    ArgoCD -->|applies manifests| OpenWebUI

    OpenWebUI --> Longhorn
    Office & Media --> ZFS

    Vault -->|injects secrets| Office
    Vault -->|injects secrets| Media
    Vault -->|injects secrets| OpenWebUI

    ZFS -->|backed up to| PBS
    Longhorn -->|backed up to| PBS
```

## Quick Start

1. **Build VM images** - Use Packer to create base images for your hypervisor
2. **Provision infrastructure** - Apply OpenTofu configurations to spin up virtual machines
3. **Deploy applications** - Run Ansible playbooks to install and configure services

For details on each step, explore the corresponding directory in this project.

## Project Structure

```
homelab/
├── ansible/        # Application deployment automation
├── docs/           # Architecture documentation and decisions
├── kubernetes/     # Kubernetes manifests (not currently deployed)
├── packer/         # VM image definitions
└── tofu/           # Infrastructure provisioning
```

## For Others

This is a personal project, but I welcome questions, discussions, and ideas from others building similar infrastructure. If you're:
- **Learning infrastructure concepts** - explore the code and architectural decisions
- **Building your own homelab** - adapt and use what works for your setup
- **Curious about specific decisions** - check [docs/decisions/](docs/decisions/) for the reasoning behind key choices

Feel free to open discussions or ask questions about how things are implemented.

## License

Licensed under [GPL-3.0](LICENSE).
