locals {
  paperless_app = "paperless-ngx"
}

resource "vault_kv_secret_v2" "paperless" {
  mount = vault_mount.kv.path
  name  = local.paperless_app
  data_json = jsonencode({
    PAPERLESS_SECRET_KEY = "changeme"
    PAPERLESS_DBPASS     = "changeme"
    SAMBA_USER           = "changme"
    SAMBA_PASSWORD       = "changme"
  })
  lifecycle {
    ignore_changes = [data_json]
  }
}

data "vault_policy_document" "paperless" {
  rule {
    path         = "${vault_mount.kv.path}/data/${local.paperless_app}"
    capabilities = ["read"]
  }
}

resource "vault_policy" "paperless" {
  name   = "policy-${local.paperless_app}"
  policy = data.vault_policy_document.paperless.hcl
}

resource "vault_kubernetes_auth_backend_role" "paperless_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "role-${local.paperless_app}"
  bound_service_account_names      = ["paperless-ngx-sa"]
  bound_service_account_namespaces = ["paperless-ngx"]
  token_ttl                        = 60 * 60
  token_max_ttl                    = 60 * 60 * 24
  token_policies                   = [vault_policy.paperless.name]
}
