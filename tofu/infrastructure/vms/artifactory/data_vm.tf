locals {
  data_disk_size = 100
}

module "data_vm" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  node_name        = var.proxmox_node_name
  size             = local.data_disk_size
}
