locals {
  application_name        = "immich"
  app_version             = "v2.4.1"
  vm_name                 = local.application_name
  mount_path              = "/mnt/${local.application_name}"
  db_mount_path           = "/mnt/database"
  db_data                 = "${local.db_mount_path}/data"
  application_directory   = "/opt/${local.application_name}"
  docker_compose_filepath = "${local.application_directory}/docker-compose.yaml"
  env_filepath            = "${local.application_directory}/.env"
}
