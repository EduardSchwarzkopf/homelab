module "pihole" {
  source            = "./pihole"
  pihole_password   = var.pihole_password
  proxmox_node_name = var.proxmox_node_name
}

variable "pihole_password" {
  type      = string
  sensitive = true
}
