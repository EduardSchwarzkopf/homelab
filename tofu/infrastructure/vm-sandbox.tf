
module "vm-sandbox" {
  source = "./vms/sandbox"

  proxmox_node_name = var.proxmox_node_name
}

