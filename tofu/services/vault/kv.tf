resource "vault_mount" "kv" {
  path        = "apps"
  type        = "kv"
  description = "KV v2 mount for app secrets"
  options     = { version = "2" }
}
