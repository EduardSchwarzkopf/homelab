
module "backup_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  size             = 1500
  node_name        = var.proxmox_node_name
  datastore_id     = "zfs-nas"
  backup_tier      = 0
}

module "config_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "${local.vm_name}-config"
  size             = 1
  node_name        = var.proxmox_node_name
  datastore_id     = "zfs-longhorn"
  backup_tier      = 2
}
