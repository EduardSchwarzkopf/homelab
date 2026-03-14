resource "vault_kv_secret_v2" "immich" {
  mount = vault_mount.kv.path
  name  = "immich"
  data_json = jsonencode({
    DB_PASSWORD = "changeme"
  })
  lifecycle {
    ignore_changes = [data_json]
  }
}
