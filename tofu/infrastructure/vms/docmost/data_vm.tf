module "disk" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = local.vm_name
  node_name        = var.proxmox_node_name
  datastore_id     = "zfs-nas"
  size             = 100
  backup_tier      = 2
}
