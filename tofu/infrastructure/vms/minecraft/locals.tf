locals {
  application_name        = "minecraft"
  vm_name                 = local.application_name
  mount_path              = "/mnt/${local.application_name}"
  minecraft_port          = 25565
  minecraft_home          = "/opt/${local.application_name}"
  docker_compose_filepath = "${local.minecraft_home}/docker-compose.yaml"
}
