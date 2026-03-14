locals {

  application_name      = "paperless"
  application_directory = "/opt/${local.application_name}"
  mount_path            = "/mnt/${local.application_name}"

  paperless = {
    version                 = "2.20.10"
    env_filepath            = "${local.application_directory}/.env"
    data_dir                = "${local.mount_path}/data"
    media_dir               = "${local.mount_path}/media"
    docker_compose_filepath = "${local.application_directory}/docker-compose.yaml"
  }

  vm_name = local.application_name
}
