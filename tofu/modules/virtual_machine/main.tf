data "proxmox_virtual_environment_vm" "template" {
  node_name = var.proxmox_node_name
  vm_id     = var.clone_vm_id
}

resource "terraform_data" "created_at" {
  input = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())

  lifecycle {
    replace_triggered_by = [terraform_data.cloud_config]
    ignore_changes       = [input]
  }
}

resource "proxmox_virtual_environment_vm" "server" {
  node_name = var.proxmox_node_name
  vm_id     = var.vm_id
  name      = var.vm_name

  description = <<-EOF
  Role:        ${var.role}

  Deployed:    ${terraform_data.created_at.output}

  Notes:       Managed by OpenTofu. Do not edit in UI.
EOF

  tags = concat(data.proxmox_virtual_environment_vm.template.tags, ["type-server", "env-${var.environment}"], var.use_gpu ? ["gpu"] : [], var.tags)

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

  dynamic "disk" {
    for_each = var.additional_disks
    content {
      datastore_id      = disk.value.datastore_id
      path_in_datastore = proxmox_virtual_environment_vm.data_disk_vm[disk.key].disk[0].path_in_datastore
      file_format       = disk.value.file_format
      size              = disk.value.size
      interface         = "scsi${1 + index(keys(var.additional_disks), disk.key)}"
    }
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

  dynamic "hostpci" {
    for_each = var.use_gpu ? [1] : []
    content {
      device  = "hostpci0"
      mapping = "gpu-gtx1060"
      xvga    = true
    }
  }
}

resource "local_file" "debug_cloud_config" {
  count    = var.cloud_config_debug ? 1 : 0
  content  = terraform_data.cloud_config.output
  filename = "debug/cloud-config-${var.vm_name}.yaml"
}
