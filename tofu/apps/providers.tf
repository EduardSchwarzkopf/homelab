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
  }
}

# Vault provider will read VAULT_ADDR and VAULT_TOKEN from env by default.
provider "vault" {}

# Environment variable-based authentication - 
# NGINXPROXYMANAGER_PASSWORD
# NGINXPROXYMANAGER_URL
# NGINXPROXYMANAGER_USERNAME
provider "nginxproxymanager" {}

provider "postgresql" {
  host      = local.postgres_host
  port      = 5432
  username  = data.vault_kv_secret_v2.postgres.data["username"]
  password  = data.vault_kv_secret_v2.postgres.data["password"]
  sslmode   = "disable"
  superuser = true
}
