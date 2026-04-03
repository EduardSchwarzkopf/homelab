output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.server.id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = var.vm_name
}

