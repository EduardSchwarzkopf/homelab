locals {
  file_format = "raw"
}
resource "proxmox_virtual_environment_vm" "data_disk_vm" {
  name      = "${var.consumer_vm_name}-data-vm"
  node_name = var.node_name
  started   = false
  on_boot   = false
  tags      = concat(["data-vm", "do-not-start"], var.additional_tags)
  pool_id   = var.pool_id

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
