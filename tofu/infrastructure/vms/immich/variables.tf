variable "proxmox_node_name" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
