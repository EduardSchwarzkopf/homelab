
locals {
  debian_vm_id                 = 102
  nas_datastore_id             = "zfs-nas"
  default_environment          = "prod"
  default_os_disk_datastore_id = "vm-os-pool"
  default_os_disk_size         = 10

  virtual_machines = {
    plane = {
      role         = "Ticket System"
      cpu_cores    = 1
      memory_gb    = 2
      os_disk_size = 15
      data_disk = {
        data = { datastore_id = local.nas_datastore_id
          size        = 20
          backup_tier = 2
        }
      }
    }
    docmost = {
      role         = "Knowledge Management"
      cpu_cores    = 2
      memory_gb    = 4
      os_disk_size = 20
      data_disk = {
        data = {
          datastore_id = local.nas_datastore_id
          size         = 100
          backup_tier  = 2
        }
      }
    }
  }
}

data "vault_kv_secret_v2" "authorized_key" {
  mount = "kv-apps"
  name  = "ssh_authorized_key"
}

module "virtual_machine" {
  for_each = local.virtual_machines
  source   = "./modules/virtual_machine"

  vm_name              = each.key
  role                 = each.value.role
  environment          = try(each.value.environment, local.default_environment)
  tags                 = try(each.value.tags, [])
  clone_vm_id          = try(each.value.clone_vm_id, local.debian_vm_id)
  cpu_cores            = each.value.cpu_cores
  memory_gb            = each.value.memory_gb
  os_disk_datastore_id = try(each.value.os_disk_datastore_id, local.default_os_disk_datastore_id)
  os_disk_size         = try(each.value.os_disk_size, local.default_os_disk_size)
  ssh_authorized_keys  = [data.vault_kv_secret_v2.authorized_key.data["public_key"]]
  additional_disks = can(each.value.data_disk) ? {
    for disk_key, disk in each.value.data_disk : disk_key => {
      datastore_id = disk.datastore_id
      size         = disk.size
      backup_tier  = disk.backup_tier
    }
  } : {}
}

output "vm_description" {

  value = module.virtual_machine["plane"].description
}
