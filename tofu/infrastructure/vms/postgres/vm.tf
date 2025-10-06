module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 5432
  vm_name              = local.vm_name
  role                 = "Postgres database server"
  environment          = "prod"
  tags                 = ["ubuntu", "database", "postgres", "prod"]
  clone_vm_id          = 100
  cpu_cores            = 4
  memory_gb            = 16
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 50


  cloud_init = {
    hostname = local.vm_name
    packages = [
      "apt-transport-https",
      "ca-certificates",
      "curl",
      "gnupg",
      "software-properties-common"
    ]
    write_files = [
      {
        path = "/home/ubuntu/docker-compose.yml"
        content = templatefile("${path.module}/templates/docker-compose.tpl.yaml", {
          POSTGRES_USER            = local.postgres_user
          POSTGRES_PASSWORD        = var.postgres_password
          POSTGRES_PORT            = local.postgres_port
          PGADMIN_DEFAULT_PASSWORD = var.pgadmin_password
          PGADMIN_DEFAULT_EMAIL    = var.pgadmin_email
          POSTGRES_DATA_PATH       = local.postgres_data_path
          PGADMIN_DATA_PATH        = local.pgadmin_data_path
        })
        owner       = "ubuntu:ubuntu"
        permissions = "0644"
        defer       = false
      }
    ]
    bootstrap_script = templatefile("${path.module}/templates/bootstrap.tpl.sh", {
      MOUNT_PATH        = local.mount_path
      PGADMIN_DATA_PATH = local.pgadmin_data_path
    })
  }

  data_disk = {
    datastore_id      = proxmox_virtual_environment_vm.postgres_data_vm.disk[0].datastore_id
    size              = proxmox_virtual_environment_vm.postgres_data_vm.disk[0].size
    file_format       = try(proxmox_virtual_environment_vm.postgres_data_vm.disk[0].file_format, null)
    path_in_datastore = try(proxmox_virtual_environment_vm.postgres_data_vm.disk[0].path_in_datastore, null)
    mount_path        = local.mount_path
  }
}
