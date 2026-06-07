
locals {
  debian_vm_id                 = 100
  nas_datastore_id             = "zfs-nas"
  default_environment          = "prod"
  default_os_disk_datastore_id = "vm-os-pool"
  default_os_disk_size         = 10

  pbs_config = {
    mount_script_filepath = "/tmp/mount-additional-disk.sh"
  }

  virtual_machines = {
    games = {
      role         = "Gaming Server"
      cpu_cores    = 4
      memory_gb    = 8
      os_disk_size = 30
      additional_disks = {
      }
    }
    ai = {
      role         = "AI Assistent Server"
      cpu_cores    = 2
      memory_gb    = 4
      os_disk_size = 50
      data_disk = {
        hermes = {
          datastore_id = local.nas_datastore_id
          size         = 10
          backup_tier  = 2
        }
      }
    }
    utility = {
      role         = "Utility Server"
      cpu_cores    = 2
      memory_gb    = 4
      os_disk_size = 50
    }
    database = {
      role         = "Databases"
      cpu_cores    = 4
      memory_gb    = 8
      os_disk_size = 20
      data_disk = {
        postgres = {
          datastore_id = local.nas_datastore_id
          size         = 20
          backup_tier  = 1
        }
        postgres-vectorchord = {
          datastore_id = local.nas_datastore_id
          size         = 10
          backup_tier  = 2
        }
      }
    }
    backup = {
      role         = "Proxmox Backup Server"
      cpu_cores    = 2
      memory_gb    = 4
      os_disk_size = 32
      tags         = ["backup"]
      cloud_init = {
        bootstrap_script = templatefile("${path.module}/data/vms/pbs/bootstrap.sh.tftpl", {
          config = local.pbs_config
        })

        packages = ["isc-dhcp-client"]
        write_files = [
          {
            path        = local.pbs_config.mount_script_filepath
            content     = file("${path.module}/data/scripts/mount-additional-disk.sh")
            owner       = "root"
            permissions = "0644"
          }
        ]
      }
      data_disk = {
        backup = {
          datastore_id = local.nas_datastore_id
          size         = 1500
          backup_tier  = 0
        }
        pbs-config = {
          datastore_id = "zfs-longhorn"
          size         = 1
          backup_tier  = 2
        }
      }
    }
    media = {
      role         = "Media Applications"
      cpu_cores    = 2
      memory_gb    = 4
      os_disk_size = 20
      gpu          = true
      data_disk = {
        snes-archive = {
          datastore_id = local.nas_datastore_id
          size         = 1
          backup_tier  = 4
        }
        n64-archive = {
          datastore_id = local.nas_datastore_id
          size         = 3
          backup_tier  = 4
        }
        gamecube-archive = {
          datastore_id = local.nas_datastore_id
          size         = 40
          backup_tier  = 4
        }
        immich = {
          datastore_id = local.nas_datastore_id
          size         = 1000
          backup_tier  = 2
        }
      }
    }
    office = {
      role         = "Productivity Applications"
      cpu_cores    = 4
      memory_gb    = 8
      os_disk_size = 20
      data_disk = {
        plane = {
          datastore_id = local.nas_datastore_id
          size         = 50
          backup_tier  = 2
        }
        docmost = {
          datastore_id = local.nas_datastore_id
          size         = 100
          backup_tier  = 2
        }
        paperless = {
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
  use_gpu              = try(each.value.use_gpu, false)
  os_disk_datastore_id = try(each.value.os_disk_datastore_id, local.default_os_disk_datastore_id)
  os_disk_size         = try(each.value.os_disk_size, local.default_os_disk_size)
  ssh_authorized_keys  = [data.vault_kv_secret_v2.authorized_key.data["public_key"]]
  cloud_init           = try(each.value.cloud_init, {})
  additional_disks = can(each.value.data_disk) ? {
    for disk_key, disk in each.value.data_disk : disk_key => {
      datastore_id = disk.datastore_id
      size         = disk.size
      backup_tier  = disk.backup_tier
    }
  } : {}
}
