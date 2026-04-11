terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.81.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

