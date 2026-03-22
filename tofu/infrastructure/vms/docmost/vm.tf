module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_name              = local.vm_name
  role                 = "Knowledge Management"
  environment          = "prod"
  tags                 = [local.application_name]
  clone_vm_id          = 102
  cpu_cores            = 2
  memory_gb            = 4
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 20

  cloud_init = {
    bootstrap_script = file("${path.module}/data/bootstrap.sh")
  }

  additional_disks = [{
    datastore_id      = module.disk.datastore_id
    size              = module.disk.size
    file_format       = module.disk.file_format
    path_in_datastore = module.disk.path_in_datastore
    mount_path        = local.mount_path
    }
  ]
}
