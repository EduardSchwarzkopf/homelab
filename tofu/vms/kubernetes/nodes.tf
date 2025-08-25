
module "controlplane" {
  source = "./modules/node"

  proxmox_node_name = var.proxmox_node_name
  count             = 1
  cluster_name      = local.cluster_name
  vm_id_start       = 500
  role              = "controlplane"
  disk_size         = 100
}


module "worker" {
  source = "./modules/node"

  proxmox_node_name = var.proxmox_node_name
  count             = 1
  cluster_name      = local.cluster_name
  vm_id_start       = 600
  role              = "worker"
  disk_size         = 100
  memory            = 4
  cpu_cores         = 4
}
