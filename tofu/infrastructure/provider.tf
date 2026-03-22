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

# Vault provider will read VAULT_ADDR and VAULT_TOKEN from env by default.
provider "vault" {
  address = "https://vault.lan.schwarzkopf.center"
}
