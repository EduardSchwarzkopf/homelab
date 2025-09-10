variable "pihole_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node_name" {
  type = string
}
