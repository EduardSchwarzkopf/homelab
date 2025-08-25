module "vm-kubernetes" {
  source = "./vms/kubernetes"

  proxmox_node_name = var.proxmox_node_name
  talos_version     = "v1.10.5"
}

