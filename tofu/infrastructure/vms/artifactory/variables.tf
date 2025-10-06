variable "proxmox_node_name" {
  type = string
}

variable "postgres_host" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}
