terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.109.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    pihole = {
      source  = "ryanwholey/pihole"
      version = "2.0.0-beta.1"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
    vault = {
      source  = "opentofu/vault"
      version = "4.4.0"
    }
  }
}
