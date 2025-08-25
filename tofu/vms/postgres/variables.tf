variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "pgadmin_email" {
  type      = string
  sensitive = true
}

variable "pgadmin_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node_name" {
  type = string
}
