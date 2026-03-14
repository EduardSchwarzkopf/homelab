variable "paperless_db_password" {
  type      = string
  sensitive = true
}

variable "paperless_secret_key" {
  type      = string
  sensitive = true
}

module "vm-paperless" {
  source = "./vms/paperless"

  proxmox_node_name    = var.proxmox_node_name
  db_password          = var.paperless_db_password
  paperless_secret_key = var.paperless_secret_key
}
