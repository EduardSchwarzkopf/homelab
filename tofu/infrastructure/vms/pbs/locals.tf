locals {
  application_name = "proxmox-backup-server"
  vm_name          = local.application_name

  backup_datastore_name = "backups"
  backup_mnt_path       = "/mnt/${local.backup_datastore_name}"
}
