resource "proxmox_virtual_environment_vm" "data_disk_vm" {
  for_each  = var.additional_disks
  name      = "${var.vm_name}-${each.key}-vm"
  node_name = var.proxmox_node_name
  started   = false
  on_boot   = false
  tags      = ["data-vm", "do-not-start", "backup-tier-${each.value.backup_tier}"]
  pool_id   = "tier-${each.value.backup_tier}"

  disk {
    datastore_id = each.value.datastore_id
    interface    = "scsi0"
    size         = each.value.size
    file_format  = each.value.file_format
  }

  lifecycle {
    prevent_destroy = true
  }
}
