module "vm-vault" {
  source = "./vms/vault"

  proxmox_node_name = var.proxmox_node_name
}
