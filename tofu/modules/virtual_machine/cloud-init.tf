locals {
  templates_dir = "${path.module}/templates"
  scripts_dir   = "${path.module}/scripts"
}

resource "terraform_data" "cloud_config" {
  input = templatefile("${local.templates_dir}/cloud-config.yaml.tftpl", {
    hostname            = var.vm_name
    ssh_authorized_keys = var.ssh_authorized_keys
    packages            = var.cloud_init.packages
    write_files         = var.cloud_init.write_files
    bootstrap_script    = var.cloud_init.bootstrap_script
    resize_root_script  = file("${local.scripts_dir}/resize-root-disk.sh")
  })
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data      = terraform_data.cloud_config.output
    file_name = "${var.vm_name}.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_metadata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data      = <<-EOF
    #cloud-config
    local-hostname: ${var.vm_name}
    EOF
    file_name = "${var.vm_name}.meta-data.yaml"
  }
}
