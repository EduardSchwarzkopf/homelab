resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

data "external" "k8s_cluster_info" {
  program = ["bash", "data/get_k8s_info.sh"]
}

resource "vault_kubernetes_auth_backend_config" "k8s_cfg" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = data.external.k8s_cluster_info.result["host"]
  kubernetes_ca_cert = data.external.k8s_cluster_info.result["ca_cert"]
  token_reviewer_jwt = data.external.k8s_cluster_info.result["token"]
  issuer             = "https://kubernetes.default.svc"
}
