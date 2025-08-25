terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.81.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.3"
    }
  }
}

provider "talos" {}
