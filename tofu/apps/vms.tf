locals {
  vm_apps      = { for k, v in local.apps : k => v if can(v.vm) }
  vm_disk_apps = { for k, v in local.apps : k => v if can(v.vm.data_disk) }
}

module "disk" {
  for_each = local.vm_disk_apps
  source   = "../infrastructure/vms/modules/data_disk_vm"

  datastore_id     = each.value.vm.data_disk.datastore_id
  consumer_vm_name = each.key
  size             = each.value.vm.data_disk.size
  backup_tier      = each.value.vm.data_disk.backup_tier
}

module "server" {
  for_each = local.vm_apps
  source   = "../infrastructure/vms/modules/server"

  vm_name              = each.key
  role                 = each.value.vm.role
  environment          = each.value.vm.environment
  tags                 = [each.key]
  clone_vm_id          = each.value.vm.clone_vm_id
  cpu_cores            = each.value.vm.cpu_cores
  memory_gb            = each.value.vm.memory_gb
  os_disk_datastore_id = each.value.vm.os_disk_datastore_id
  os_disk_size         = each.value.vm.os_disk_size
  additional_disks = can(each.value.vm.data_disk) ? [{
    datastore_id      = module.disk[each.key].datastore_id
    size              = module.disk[each.key].size
    file_format       = module.disk[each.key].file_format
    path_in_datastore = module.disk[each.key].path_in_datastore
    mount_path        = each.value.vm.data_disk.mount_path
  }] : []
}
