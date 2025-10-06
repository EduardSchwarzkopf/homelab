module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = 8081
  vm_name              = local.vm_name
  role                 = "Artifactory"
  environment          = "prod"
  tags                 = ["ubuntu", "artifacts", "artifactory", "prod"]
  clone_vm_id          = 100
  cpu_cores            = 4
  memory_gb            = 8
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 50

  cloud_init = {
    hostname = local.vm_name
    bootstrap_script = templatefile("${path.module}/templates/bootstrap.tpl.sh", {
      MOUNT_PATH                = local.mount_path
      ARTIFACTORY_HOME_DIR      = local.application_home_dir
      TEMP_SYSTEM_YAML_FILEPATH = local.temp_system_yaml_filepath
      TEMP_BINARYSTORE_FILEPATH = local.temp_binarystore_filepath
      APPLICATION_DATA_DIR      = local.application_data_dir
      APPLICATION_CONFIG_DIR    = local.application_config_dir
    })

    write_files = [
      {
        path = local.temp_binarystore_filepath
        content = templatefile("${path.module}/templates/binarystore.tpl.xml", {
          DATA_DIR = local.application_data_dir
        })
        owner       = "root"
        permissions = "0644"
        defer       = false
      },
      {
        path        = local.master_key_filepath
        content     = random_bytes.master_key.hex
        owner       = "root"
        permissions = "0600"
        defer       = true
      },
      {
        path = local.temp_system_yaml_filepath
        content = templatefile("${path.module}/templates/system.tpl.yaml", {
          POSTGRES_HOST       = var.postgres_host
          POSTGRES_USERNAME   = local.application_name
          POSTGRES_DATABASE   = local.application_name
          POSTGRES_PASSWORD   = var.postgres_password
          MASTER_KEY_FILEPATH = local.master_key_filepath
        })
        owner       = "root"
        permissions = "0644"
        defer       = false
      }
    ]
  }

  data_disk = {
    datastore_id      = module.data_vm.datastore_id
    size              = local.data_disk_size
    file_format       = module.data_vm.file_format
    path_in_datastore = module.data_vm.path_in_datastore
    mount_path        = local.mount_path
  }
}
