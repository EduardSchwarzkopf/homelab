
module "models" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  size             = 150
  node_name        = var.proxmox_node_name
}
