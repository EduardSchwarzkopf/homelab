locals {
  templates_dir = "${path.module}/templates"
  scripts_dir   = "${path.module}/scripts"
}

resource "terraform_data" "cloud_config" {
  input = templatefile("${local.templates_dir}/cloud-config.tpl.yaml", {
    hostname                      = var.vm_name
    ssh_authorized_keys           = [trimspace(tls_private_key.vm_key.public_key_openssh)]
    packages                      = var.cloud_init.packages
    write_files                   = var.cloud_init.write_files
    bootstrap_script              = var.cloud_init.bootstrap_script
    resize_root_script            = file("${local.scripts_dir}/resize-root-disk.sh")
    mount_additional_disks_script = file("${local.scripts_dir}/mount-additional-disks.sh")
    additional_mounts = [
      for idx, disk in var.additional_disks : {
        mount_path  = disk.mount_path
        scsi_number = "${1 + idx}"
      }
    ]
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
