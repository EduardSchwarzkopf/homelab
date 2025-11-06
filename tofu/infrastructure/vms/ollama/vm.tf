module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 11343
  vm_name              = local.vm_name
  role                 = "AI Model Provider"
  environment          = "prod"
  tags                 = ["ollama", "ai"]
  clone_vm_id          = 100
  cpu_cores            = 6
  memory_gb            = 24
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 30
  use_gpu              = true
  cloud_init = {
    hostname = local.vm_name
    packages = ["nvidia-driver-555", "nvidia-cuda-toolkit"]
    bootstrap_script = templatefile("${path.module}/templates/bootstrap.tpl.sh", {
      MOUNT_PATH = local.mount_path
    })
  }

  additional_disks = [
    {
      datastore_id      = module.models.datastore_id
      size              = module.models.size
      file_format       = module.models.file_format
      path_in_datastore = module.models.path_in_datastore
      mount_path        = local.mount_path
    },
  ]
}
