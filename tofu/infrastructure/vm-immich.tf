
variable "immich_db_password" {
  type      = string
  sensitive = true
}


module "vm-immich" {
  source = "./vms/immich"

  proxmox_node_name = var.proxmox_node_name
  db_password       = var.immich_db_password
}

