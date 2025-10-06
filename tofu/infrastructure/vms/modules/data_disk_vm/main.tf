resource "proxmox_virtual_environment_vm" "data_disk_vm" {
  name      = "${var.consumer_vm_name}-data-vm"
  node_name = var.node_name
  started   = false
  on_boot   = false
  tags      = concat(["ubuntu", "data-vm", "do-not-start"], var.additional_tags)

  disk {
    datastore_id = "zfs-longhorn"
    interface    = "scsi0"
    size         = var.size
  }

  lifecycle {
    prevent_destroy = true
  }
}
