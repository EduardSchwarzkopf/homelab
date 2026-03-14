locals {
  file = {
    owner       = "ubuntu:ubuntu"
    permissions = "0644"
  }
  template_dir = "${path.module}/templates"
}

module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_name              = local.vm_name
  role                 = "Documenten Management"
  environment          = "prod"
  tags                 = [local.application_name]
  clone_vm_id          = 100
  cpu_cores            = 2
  memory_gb            = 4
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 30

  cloud_init = {
    write_files = [
      {
        path = local.paperless.docker_compose_filepath
        content = templatefile("${local.template_dir}/docker-compose.yaml.tftpl", {
          paperless = local.paperless
        })
        owner       = local.file.owner
        permissions = local.file.permissions
      },
      {
        path = local.paperless.env_filepath
        content = templatefile("${local.template_dir}/.env.tftpl", {
          PAPERLESS_DBNAME     = local.application_name
          PAPERLESS_DBPASS     = var.db_password
          PAPERLESS_SECRET_KEY = var.paperless_secret_key
        })
        owner       = local.file.owner
        permissions = local.file.permissions
      }
    ]
    bootstrap_script = templatefile("${local.template_dir}/bootstrap.sh.tftpl", {
      docker_compose_filepath = local.paperless.docker_compose_filepath
    })
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
