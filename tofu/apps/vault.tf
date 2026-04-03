resource "vault_mount" "kv_apps" {
  path        = "kv-apps"
  type        = "kv"
  description = "KV v2 mount for app secrets"
  options     = { version = "2" }
}

data "vault_kv_secret_v2" "postgres" {
  mount = "kv-apps"
  name  = "postgres"
}

resource "vault_kv_secret_v2" "app_database" {
  for_each = local.db_apps
  mount    = vault_mount.kv_apps.path
  name     = "${each.key}/database"
  data_json = jsonencode({
    username = each.key
    password = random_password.app_database[each.key].result
  })
}
