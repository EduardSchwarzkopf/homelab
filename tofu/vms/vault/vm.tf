resource "proxmox_virtual_environment_vm" "data_vm" {
  node_name = var.proxmox_node_name
  started   = false
  on_boot   = false
  name      = "${local.vm_name}-data-vm"
  tags      = ["ubuntu", "data-vm", "vault", "prod", "do-not-start"]


  disk {
    datastore_id = "zfs-longhorn"
    interface    = "scsi0"
    size         = 10
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.proxmox_node_name
  vm_id     = 8200
  name      = local.vm_name

  description = <<-EOF
  Role:        Vault (secrets manager)

  Environment: prod
  
  Deployed:    ${timestamp()}
  
  Version:     ${local.vault_version}
  
  Notes:       Managed by Terraform. Do not edit in UI.
EOF


  tags = ["ubuntu", "vault", "prod", "security"]

  clone {
    vm_id     = 100
    node_name = var.proxmox_node_name
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8 * 1024
  }

  disk {
    datastore_id = "vm-os-pool"
    interface    = "scsi0"
    size         = 50
  }


  dynamic "disk" {
    for_each = { for idx, val in proxmox_virtual_environment_vm.data_vm.disk : idx => val }
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
    meta_data_file_id = proxmox_virtual_environment_file.cloud_metadata.id
  }

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.cloud_config]
  }
}


resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "key" {
  filename = "keys/${local.vm_name}.key"
  content  = tls_private_key.vm_key.private_key_pem

  file_permission = 600
}
