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

    subgraph Physical["Physical — 192.168.178.0/24"]
        FB["Fritzbox · 192.168.178.1<br/>─────<br/>Default Gateway · VPN Endpoint"]
    end

    subgraph RPi["Raspberry Pi"]
        PH["Pi‑hole<br/>─────<br/>DNS :53 · DHCP Server"]
        NPM["Nginx Proxy Manager<br/>─────<br/>Reverse Proxy :443"]
        VAULT["HashiCorp Vault<br/>─────<br/>vault.lan.schwarzkopf.center"]
    end

    subgraph Proxmox["Proxmox VE — Homeserver"]
        subgraph VMs["VMs — Debian 12 · Podman"]
            OFF["office<br/>──────<br/>Plane · Leaf Wiki<br/>Paperless · Docmost<br/>PostgreSQL :5432"]

            MED["media<br/>──────<br/>Immich<br/>Retro Games (SNES / N64 / GC)<br/>Postgres‑VectorChord :5433"]

            GAMES["games"]
            UTIL["utility"]
            BACKUP["backup<br/>Proxmox Backup Server"]
        end

        subgraph Storage["Storage"]
            ZFS["ZFS Pools<br/>zfs‑nas · vm‑os‑pool"]
        end

    end

    User -->|"WAN"| FB
    FB -->|"LAN"| PH
    FB -->|"LAN"| Proxmox

    PH -->|"DHCP · DNS :53"| User
    PH -.->|"upstream DNS"| FB

    NPM -->|"reverse proxy :443"| OFF
    NPM -->|"reverse proxy :443"| MED
    NPM -->|"reverse proxy :443"| GAMES

    OFF -->|"data"| ZFS
    MED -->|"data"| ZFS
    GAMES -->|"data"| ZFS
    UTIL -->|"data"| ZFS
    BACKUP -->|"backups"| ZFS

    OFF -.->|"secrets"| VAULT
    MED -.->|"secrets"| VAULT
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
