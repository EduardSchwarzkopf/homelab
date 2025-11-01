resource "proxmox_virtual_environment_pool" "data_vm_pool" {
  comment = "Managed by OpenTofu"
  pool_id = "data-vms"
}
