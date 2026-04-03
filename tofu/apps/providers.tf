# Vault provider will read VAULT_ADDR and VAULT_TOKEN from env by default.
provider "vault" {
  address = "https://vault.${local.lan_domain}"
}

# Environment variable-based authentication
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
