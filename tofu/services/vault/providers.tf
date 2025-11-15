terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "opentofu/vault"
      version = "4.4.0"
    }
    external = {
      source  = "opentofu/external"
      version = "2.3.4"
    }
  }
}

# Vault provider will read VAULT_ADDR and VAULT_TOKEN from env by default.
provider "vault" {}
