resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data = templatefile("${path.module}/templates/cloud-config.tpl.yaml", {
      public_key_openssh = trimspace(tls_private_key.vm_key.public_key_openssh)
      HOSTNAME           = local.vm_name
      VAULT_VERSION      = local.vault_version
      MOUNT_PATH         = local.mount_path
    })

    file_name = "${local.vm_name}.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_metadata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data      = <<-EOF
    #cloud-config
    local-hostname: ${local.vm_name}
    EOF
    file_name = "${local.vm_name}.meta-data.yaml"
  }
}
