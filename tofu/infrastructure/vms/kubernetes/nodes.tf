
module "controlplane" {
  source = "./modules/node"

  proxmox_node_name = var.proxmox_node_name
  count             = 1
  cluster_name      = local.cluster_name
  role              = "controlplane"
  disk_size         = 100
}


module "worker" {
  source = "./modules/node"

  proxmox_node_name = var.proxmox_node_name
  count             = 1
  cluster_name      = local.cluster_name
  role              = "worker"
  disk_size         = 100
  memory            = 4
  cpu_cores         = 4

  longhorn_disk_enabled = true
  longhorn_disk_size    = 100
  longhorn_datastore_id = "zfs-longhorn"
}
