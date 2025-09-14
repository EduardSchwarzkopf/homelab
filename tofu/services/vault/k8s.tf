resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "k8s_cfg" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://homelab-controlplane-01:6443"
  kubernetes_ca_cert = file("data/k8s-ca.cert")
  token_reviewer_jwt = var.token_reviewer_jwt
  issuer             = "https://kubernetes.default.svc"
}
