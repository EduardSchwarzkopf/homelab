variable "proxmox_node_name" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "paperless_secret_key" {
  type      = string
  sensitive = true
}

variable "paperless_smb_password" {
  type      = string
  sensitive = true
}
