output "id" {
  description = "ID of the data disk VM"
  value       = proxmox_virtual_environment_vm.data_disk_vm.id
}

output "name" {
  description = "Name of the data disk VM"
  value       = proxmox_virtual_environment_vm.data_disk_vm.name
}
