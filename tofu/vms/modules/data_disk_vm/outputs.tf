locals {
  data_vm = proxmox_virtual_environment_vm.data_disk_vm.disk[0]
}

output "id" {
  description = "ID of the data disk VM"
  value       = proxmox_virtual_environment_vm.data_disk_vm.id
}

output "name" {
  description = "Name of the data disk VM"
  value       = proxmox_virtual_environment_vm.data_disk_vm.name
}

output "datastore_id" {
  description = "Datastore where the disk is located"
  value       = var.datastore_id
}

output "file_format" {
  description = "File format of the disk"
  value       = local.file_format
}

output "path_in_datastore" {
  description = "Path to the disk in the datastore"
  value       = try(local.data_vm.path_in_datastore, null)
}

output "size" {
  description = "Size of the disk in bytes"
  value       = local.data_vm.size
}

output "backup_tier" {
  description = "Backup tier assigned to this data disk"
  value       = var.backup_tier
}

