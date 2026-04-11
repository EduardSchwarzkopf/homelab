
module "vm-pbs" {
  source = "./vms/pbs"

  proxmox_node_name = var.proxmox_node_name
}

