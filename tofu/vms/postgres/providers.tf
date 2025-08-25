terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.81.0"
    }
    cloudinit = {
      source  = "opentofu/cloudinit"
      version = "2.3.7"
    }
  }
}

