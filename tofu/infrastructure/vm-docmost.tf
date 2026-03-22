module "vm-docmost" {
  source = "./vms/docmost"

  proxmox_node_name = var.proxmox_node_name
}
