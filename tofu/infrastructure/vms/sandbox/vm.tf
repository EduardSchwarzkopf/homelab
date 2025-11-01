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
  os_disk_size         = 50

  cloud_init = {
    hostname         = local.vm_name
    bootstrap_script = ""
  }
}

module "server_debian" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 1001
  vm_name              = "${local.vm_name}-debian"
  role                 = "Sandbox"
  environment          = "dev"
  tags                 = ["sandbox", "debian"]
  clone_vm_id          = 102
  cpu_cores            = 2
  memory_gb            = 4
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 15

  cloud_init = {
    hostname         = local.vm_name
    bootstrap_script = ""
  }

  additional_disks = [{
    datastore_id      = proxmox_virtual_environment_vm.this.disk[0].datastore_id
    size              = proxmox_virtual_environment_vm.this.disk[0].size
    file_format       = try(proxmox_virtual_environment_vm.this.disk[0].file_format, null)
    path_in_datastore = try(proxmox_virtual_environment_vm.this.disk[0].path_in_datastore, null)
    mount_path        = "/mnt/this"
    },
    {
      datastore_id      = proxmox_virtual_environment_vm.ubuntu.disk[0].datastore_id
      size              = proxmox_virtual_environment_vm.ubuntu.disk[0].size
      file_format       = try(proxmox_virtual_environment_vm.ubuntu.disk[0].file_format, null)
      path_in_datastore = try(proxmox_virtual_environment_vm.ubuntu.disk[0].path_in_datastore, null)
      mount_path        = "/mnt/ubuntu"
    }
  ]
}


resource "local_file" "name" {
  content  = module.server_debian.cloud_config
  filename = "debug/cloud_config.yaml"
}
