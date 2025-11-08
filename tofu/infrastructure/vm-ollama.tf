
module "vm-ollama" {
  source = "./vms/ollama"

  proxmox_node_name = var.proxmox_node_name
}

