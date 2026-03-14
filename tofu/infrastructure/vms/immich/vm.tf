module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_name              = local.vm_name
  role                 = "Photo and video management"
  environment          = "prod"
  tags                 = [local.application_name, "gaming", "java"]
  clone_vm_id          = 100
  cpu_cores            = 4
  memory_gb            = 6
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 30

  cloud_init = {
    write_files = [
      {
        path        = local.docker_compose_filepath
        content     = file("${path.module}/data/docker-compose.yaml")
        owner       = "ubuntu:ubuntu"
        permissions = "0644"
      },
      {
        path = local.env_filepath
        content = templatefile("${path.module}/templates/tpl.env", {
          IMMICH_VERSION   = local.app_version
          APPLICATION_NAME = local.application_name
          DB_DATA_LOCATION = local.db_data
          DB_PASSWORD      = var.db_password
          UPLOAD_LOCATION  = local.mount_path
        })
        owner       = "ubuntu:ubuntu"
        permissions = "0644"
      }
    ]
    bootstrap_script = templatefile("${path.module}/templates/bootstrap.tpl.sh", {
      DOCKER_COMPOSE_FILEPATH = local.docker_compose_filepath
    })
  }

  additional_disks = [{
    datastore_id      = module.disk.datastore_id
    size              = module.disk.size
    file_format       = module.disk.file_format
    path_in_datastore = module.disk.path_in_datastore
    mount_path        = local.mount_path
    }, {
    datastore_id      = module.db_disk.datastore_id
    size              = module.db_disk.size
    file_format       = module.db_disk.file_format
    path_in_datastore = module.db_disk.path_in_datastore
    mount_path        = local.db_mount_path
    }
  ]
}
