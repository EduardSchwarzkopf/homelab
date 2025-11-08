
module "controlplane" {
  source   = "./modules/node"
  vm_count = 3

  proxmox_node_name = var.proxmox_node_name
  cluster_name      = local.cluster_name
  role              = local.cp
  disk_size         = 20
}


module "worker" {
  source   = "./modules/node"
  vm_count = 2

  proxmox_node_name = var.proxmox_node_name
  cluster_name      = local.cluster_name
  role              = "worker"
  disk_size         = 30
  memory            = 4
  cpu_cores         = 4

  longhorn_disk_enabled = true
  longhorn_disk_size    = 50
  longhorn_datastore_id = "zfs-longhorn"
}
