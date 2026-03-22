terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "opentofu/vault"
      version = "4.4.0"
    }
    nginxproxymanager = {
      source  = "Sander0542/nginxproxymanager"
      version = "1.2.2"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
  }
}
