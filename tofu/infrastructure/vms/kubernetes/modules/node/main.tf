resource "proxmox_virtual_environment_vm" "vm" {
  count       = var.vm_count
  name        = format("%s-%s-%02d", var.cluster_name, var.role, count.index + 1)
  node_name   = var.proxmox_node_name
  vm_id       = var.vm_id_start + count.index
  description = format("Talos %s node %d for %s", title(var.role), count.index + 1, var.cluster_name)
  tags        = ["kubernetes", "talos", var.role]

  clone {
    vm_id     = 102
    node_name = var.proxmox_node_name
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  disk {
    datastore_id = "vm-os-pool"
    interface    = "scsi0"
    size         = var.disk_size
  }

  dynamic "disk" {
    for_each = var.longhorn_disk_enabled ? [1] : []
    content {
      datastore_id = var.longhorn_datastore_id
      interface    = "scsi1"
      size         = var.longhorn_disk_size
    }
  }

  memory {
    dedicated = var.memory * 1024
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }
}
