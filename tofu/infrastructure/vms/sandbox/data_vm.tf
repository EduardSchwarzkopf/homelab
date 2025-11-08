# resource "proxmox_virtual_environment_vm" "this" {
#   node_name = var.proxmox_node_name
#   started   = false
#   on_boot   = false
#   name      = "${local.vm_name}-data-vm"
#   tags      = ["ubuntu", "data-vm", "dev", "do-not-start"]


#   disk {
#     datastore_id = "zfs-longhorn"
#     interface    = "scsi0"
#     size         = 1
#   }
# }

# resource "proxmox_virtual_environment_vm" "ubuntu" {
#   node_name = var.proxmox_node_name
#   started   = false
#   on_boot   = false
#   name      = "${local.vm_name}-data-vm"
#   tags      = ["data-vm", "dev", "do-not-start"]


#   disk {
#     datastore_id = "zfs-longhorn"
#     interface    = "scsi0"
#     size         = 1
#   }
# }
