terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
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
  }
}

provider "proxmox" {
  endpoint  = "https://proxmox.lan.schwarzkopf.center"
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = false

  ssh {
    agent    = true
    username = var.node_ssh_user
  }
}

provider "pihole" {
  url      = "https://pihole.lan.schwarzkopf.center"
  password = var.pihole_password
}
