module "vm-minecraft" {
  source = "./vms/minecraft"

  proxmox_node_name = var.proxmox_node_name
}
