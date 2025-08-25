module "pihole" {
  source          = "./pihole"
  pihole_password = var.pihole_password
}

variable "pihole_password" {
  type      = string
  sensitive = true
}
