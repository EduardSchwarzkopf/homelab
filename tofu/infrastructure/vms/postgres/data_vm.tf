module "data_vm" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  node_name        = var.proxmox_node_name
  size             = 20
  backup_tier      = 1
}
