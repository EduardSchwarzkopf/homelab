module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 8007
  vm_name              = local.vm_name
  role                 = "Proxmox Backup Server"
  environment          = "prod"
  tags                 = ["debian", "backup", "pbs"]
  clone_vm_id          = 102
  cpu_cores            = 2
  memory_gb            = 4
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 32

  cloud_init = {
    hostname         = local.vm_name
    bootstrap_script = file("${path.module}/data/bootstrap.sh")

    packages = ["isc-dhcp-client"]
  }

  additional_disks = [
    {
      datastore_id      = module.backup_data.datastore_id
      size              = module.backup_data.size
      file_format       = module.backup_data.file_format
      path_in_datastore = module.backup_data.path_in_datastore
      mount_path        = local.backup_mnt_path
    },
    {
      datastore_id      = module.config_data.datastore_id
      size              = module.config_data.size
      file_format       = module.config_data.file_format
      path_in_datastore = module.config_data.path_in_datastore
      mount_path        = "/etc/proxmox-backup"
    },
  ]
}
