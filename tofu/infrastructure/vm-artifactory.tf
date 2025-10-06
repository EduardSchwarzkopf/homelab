module "vm-artifactory" {
  source            = "./vms/artifactory"
  proxmox_node_name = var.proxmox_node_name
  postgres_host     = module.vm-postgres.hostname
  postgres_password = var.artifactory_db_password
}

variable "artifactory_db_password" {
  type      = string
  sensitive = true
}
