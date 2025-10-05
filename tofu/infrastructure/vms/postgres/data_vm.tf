resource "proxmox_virtual_environment_vm" "postgres_data_vm" {
  node_name = var.proxmox_node_name
  started   = false
  on_boot   = false
  name      = "${local.vm_name}-data-vm"
  tags      = ["ubuntu", "data-vm", "postgres", "prod", "do-not-start"]


  disk {
    datastore_id = "zfs-longhorn"
    interface    = "scsi0"
    size         = 20
  }

  lifecycle {
    prevent_destroy = true
  }
}
