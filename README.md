# homelab

A modular, infrastructure-as-code (IaC) project for building and managing my self-hosted homelab environment. 
This repository automates the provisioning of virtual machines, Kubernetes clusters, and essential services using modern DevOps tools.

---


## Overview

**homelab** provides a reproducible, automated way to deploy and manage a home infrastructure stack. It leverages:
- **OpenTofu** for infrastructure provisioning (VMs, networking, storage)
- **Kubernetes** for container orchestration and application management
- **Packer** for building custom VM images
- **Vault, Proxmox, Longhorn, ArgoCD, and more** for secrets, virtualization, storage, and GitOps

The project is designed for flexibility, modularity, and maintainability, making it easy to extend or adapt to my homelab needs.


### Architecture

![Architecture](docs/img/homelab.drawio.svg)

---

## Prerequisites

- [OpenTofu](https://opentofu.org/)
- [Packer](https://www.packer.io/)
- [Proxmox VE](https://www.proxmox.com/) (for virtualization)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [k9s](https://k9scli.io/)

---

## Setup & Usage

### 1. Build VM Images

Use Packer to build base images for your VMs.

```sh
cd packer/linux
packer init .
packer build -var-file=ubuntu-24042.pkrvars.hcl .
```
See `packer/README.md` for more details.

### 2. Provision Infrastructure

Use Tofu/Terraform to provision VMs, networks, and storage.

```sh
cd tofu/infrastructure
tofu init
tofu plan
tofu apply
```

### 3. Deploy Kubernetes Resources

Apply Kubernetes manifests to your cluster.

```sh
cd kubernetes/bootstrap
kubectl apply -k .
```

Then deploy applications from `kubernetes/apps/` via ArgoCD.

### 4. Configure Services

- Vault, Postgres, and other services are managed under `tofu/services/`.
- See service-specific files for configuration and secrets management.

---

## Directory Details

### kubernetes/
- **apps/**: Application manifests (e.g., Paperless NGX)
- **bootstrap/**: Cluster bootstrap resources (ArgoCD, Vault, Longhorn, MetalLB, etc.)
  - See `kubernetes/bootstrap/README.md` and subdirectory READMEs for details.

### packer/
- **linux/**: Packer templates and scripts for building Linux VM images.
- See `packer/README.md` for image build instructions.

### tofu/
- **infrastructure/**: Tofu/Terraform modules for VMs, networking, storage, and Proxmox integration.
- **services/**: Service definitions and modules (Vault, Postgres, etc.)

---

## References

- [Packer Documentation](https://www.packer.io/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [OpenTofu Documentation](https://opentofu.org/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)

See also:
- `packer/README.md`
- `kubernetes/bootstrap/README.md`
- `kubernetes/bootstrap/resources/longhorn/README.md`

---

## License

This project is licensed under the terms of the [GPL-3.0 license](LICENSE).
