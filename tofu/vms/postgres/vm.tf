resource "proxmox_virtual_environment_vm" "postgres_data_vm" {
  node_name = var.proxmox_node_name
  started   = false
  on_boot   = false
  name      = "${local.vm_name}-data-vm"
  tags      = ["ubuntu", "data-vm", "postgres", "prod", "do-not-start"]


  disk {
    datastore_id = "zfs-longhorn"
    interface    = "scsi0"
    size         = 20
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "postgres_vm" {
  node_name = var.proxmox_node_name
  vm_id     = 5432
  name      = local.vm_name

  tags = ["ubuntu", "database", "postgres", "prod"]

  clone {
    vm_id     = 100
    node_name = var.proxmox_node_name
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 1024 * 16
  }

  # Boot disk
  disk {
    datastore_id = "vm-os-pool"
    interface    = "scsi0"
    size         = 50
  }

  dynamic "disk" {
    for_each = { for idx, val in proxmox_virtual_environment_vm.postgres_data_vm.disk : idx => val }
    iterator = data_disk
    content {
      datastore_id      = data_disk.value["datastore_id"]
      path_in_datastore = data_disk.value["path_in_datastore"]
      file_format       = data_disk.value["file_format"]
      size              = data_disk.value["size"]
      interface         = "scsi${data_disk.key + 1}"
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
  }

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.cloud_config]
  }
}


resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_vm_private_key" {
  value     = tls_private_key.ubuntu_vm_key.private_key_pem
  sensitive = true
}

resource "local_file" "key" {
  filename = "ubuntu.key"
  content  = tls_private_key.ubuntu_vm_key.private_key_pem

  file_permission = 600

}
