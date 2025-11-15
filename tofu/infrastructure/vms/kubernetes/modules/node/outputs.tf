locals {
  vm_map = { for i in range(var.vm_count) : "${var.role}-${i}" => proxmox_virtual_environment_vm.vm[i] }
}

output "vm_map" {
  description = "Map of VMs with static keys for for_each usage"
  value       = local.vm_map
}

output "hostnames" {
  description = "List of VM DNS hostnames (Proxmox VM names) - computed from vm_map"
  value       = toset([for vm in values(local.vm_map) : vm.name])
}

