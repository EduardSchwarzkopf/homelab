locals {

  application_name      = "paperless"
  application_directory = "/opt/${local.application_name}"
  mount_path            = "/mnt/${local.application_name}"

  paperless = {
    name                    = local.application_name
    version                 = "2.20.10"
    user_id                 = 1001
    group_id                = 1001
    env_filepath            = "${local.application_directory}/.env"
    data_dir                = "${local.mount_path}/data"
    media_dir               = "${local.mount_path}/media"
    consume_dir             = "${local.application_directory}/consume"
    docker_compose_filepath = "${local.application_directory}/docker-compose.yaml"

    smb = {
      user     = "${local.application_name}-smb"
      password = var.paperless_smb_password
    }
  }

  vm_name = local.application_name
}
