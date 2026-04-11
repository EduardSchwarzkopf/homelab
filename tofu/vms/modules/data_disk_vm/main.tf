locals {
  file_format = "raw"
  tier_name   = "tier-${var.backup_tier}"
}

resource "proxmox_virtual_environment_vm" "data_disk_vm" {
  name      = "${var.consumer_vm_name}-data-vm"
  node_name = var.node_name
  started   = false
  on_boot   = false
  tags      = concat(["data-vm", "do-not-start", "backup-${local.tier_name}"], var.additional_tags)
  pool_id   = local.tier_name

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.size
    file_format  = local.file_format
  }

  lifecycle {
    prevent_destroy = true
  }
}
