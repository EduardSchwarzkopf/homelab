locals {
  application_name          = "artifactory"
  vm_name                   = local.application_name
  temp_dir                  = "/tmp/${local.application_name}"
  mount_path                = "/mnt/${local.application_name}"
  application_home_dir      = "/opt/jfrog/artifactory"
  application_data_dir      = "${local.mount_path}/data"
  application_config_dir    = "${local.mount_path}/etc"
  master_key_filepath       = "${local.application_config_dir}/master.key"
  temp_binarystore_filepath = "${local.temp_dir}/binarystore.xml"
  temp_system_yaml_filepath = "${local.temp_dir}/system.yaml"
}
