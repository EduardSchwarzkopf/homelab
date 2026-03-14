module "disk" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  node_name        = var.proxmox_node_name
  datastore_id     = "zfs-nas"
  size             = 1000
  backup_tier      = 2
}

module "db_disk" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  node_name        = var.proxmox_node_name
  size             = 10
  backup_tier      = 2
}
