module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 1000
  vm_name              = local.vm_name
  role                 = "Sandbox"
  environment          = "dev"
  tags                 = ["sandbox"]
  clone_vm_id          = 100
  cpu_cores            = 2
  memory_gb            = 4
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 200

  cloud_init = {
    hostname         = local.vm_name
    bootstrap_script = ""
  }
}
