variable "kubernetes_csi_user_password" {
  type      = string
  sensitive = true
}

variable "iac_user_password" {
  type      = string
  sensitive = true
}

variable "packer_user_password" {
  type      = string
  sensitive = true
}

variable "wakeonlan_host" {
  type = string
}

variable "wakeonlan_ssh_user" {
  type = string
}

variable "node_ssh_user" {
  type = string
}

variable "homeserver_mac" {
  type      = string
  sensitive = true
}
