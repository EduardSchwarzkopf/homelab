resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data = templatefile("templates/cloud-config.tpl.yaml", {
      public_key_openssh = trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)
      HOSTNAME           = local.vm_name
      MOUNT_PATH         = local.mount_path
      PGADMIN_DATA_PATH  = local.pgadmin_data_path
      DOCKER_COMPOSE_ENCODED = base64encode(templatefile("templates/docker-compose.tpl.yaml", {
        POSTGRES_USER            = local.postgres_user
        POSTGRES_PASSWORD        = var.postgres_password
        POSTGRES_PORT            = local.postgres_port
        PGADMIN_DEFAULT_PASSWORD = var.pgadmin_password
        PGADMIN_DEFAULT_EMAIL    = var.pgadmin_email
        POSTGRES_DATA_PATH       = local.postgres_data_path
        PGADMIN_DATA_PATH        = local.pgadmin_data_path
      }))
    })

    file_name = "postgres.cloud-config.yaml"
  }
}
