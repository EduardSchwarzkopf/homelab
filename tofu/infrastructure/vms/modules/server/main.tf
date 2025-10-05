resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "key" {
  filename        = "keys/${var.vm_name}.key"
  content         = tls_private_key.vm_key.private_key_pem
  file_permission = 600
}

resource "terraform_data" "cloud_config" {
  input = templatefile("${path.module}/cloud-config.tpl.yaml", {
    hostname            = var.vm_name
    ssh_authorized_keys = [trimspace(tls_private_key.vm_key.public_key_openssh)]
    packages            = var.cloud_init.packages
    write_files         = var.cloud_init.write_files
    bootstrap_script    = var.cloud_init.bootstrap_script
    mount_path          = var.data_disk.mount_path
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

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.proxmox_node_name
  vm_id     = var.vm_id
  name      = var.vm_name

  description = <<-EOF
  Role:        ${var.role}
  Name:        ${var.vm_name}
  Environment: ${var.environment}
  Deployed:    ${timestamp()}
  Notes:       Managed by Terraform. Do not edit in UI.
EOF

  tags = var.tags

  clone {
    vm_id     = var.clone_vm_id
    node_name = var.proxmox_node_name
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_gb * 1024
  }

  disk {
    datastore_id = var.os_disk_datastore_id
    interface    = "scsi0"
    size         = var.os_disk_size
  }

  disk {
    datastore_id      = var.data_disk.datastore_id
    path_in_datastore = var.data_disk.path_in_datastore
    file_format       = var.data_disk.file_format
    size              = var.data_disk.size
    interface         = "scsi1"
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.cloud_metadata.id
  }

  lifecycle {
    replace_triggered_by = [terraform_data.cloud_config]
  }

}

resource "local_file" "debug_cloud_config" {
  count    = var.cloud_config_debug ? 1 : 0
  content  = terraform_data.cloud_config.output
  filename = "debug/cloud-config-${var.vm_name}.yaml"
}
