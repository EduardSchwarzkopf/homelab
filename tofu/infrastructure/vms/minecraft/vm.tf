module "server" {
  source = "../modules/server"

  proxmox_node_name    = var.proxmox_node_name
  vm_id                = local.minecraft_port
  vm_name              = local.vm_name
  role                 = "Minecraft Game Server"
  environment          = "prod"
  tags                 = [local.application_name, "gaming", "java"]
  clone_vm_id          = 100
  cpu_cores            = 4
  memory_gb            = 8
  os_disk_datastore_id = "vm-os-pool"
  os_disk_size         = 30

  cloud_init = {
    hostname = local.vm_name
    packages = [
      "openjdk-21-jre-headless",
      "curl",
      "wget",
      "git",
      "htop",
      "tmux"
    ]
    write_files = [
      {
        path = local.docker_compose_filepath
        content = templatefile("${path.module}/templates/docker-compose.tpl.yaml", {
          MINECRAFT_PORT = local.minecraft_port
          MOUNT_PATH     = local.mount_path
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
    datastore_id      = module.world_data.datastore_id
    size              = module.world_data.size
    file_format       = module.world_data.file_format
    path_in_datastore = module.world_data.path_in_datastore
    mount_path        = local.mount_path
  }]
}
