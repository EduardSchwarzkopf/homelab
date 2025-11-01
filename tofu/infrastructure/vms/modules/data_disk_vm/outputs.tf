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
  value = var.datastore_id
}

output "file_format" {
  value = local.file_format
}

output "path_in_datastore" {
  value = try(local.data_vm.path_in_datastore, null)
}

output "size" {
  value = local.data_vm.size
}
