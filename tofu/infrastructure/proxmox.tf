
module "proxmox" {
  source = "./proxmox"

  iac_user_password            = var.iac_user_password
  node_ssh_user                = var.node_ssh_user
  homeserver_mac               = var.homeserver_mac
  kubernetes_csi_user_password = var.kubernetes_csi_user_password
  packer_user_password         = var.packer_user_password
  wakeonlan_host               = var.wakeonlan_host
  wakeonlan_ssh_user           = var.wakeonlan_ssh_user
}


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

