resource "random_pet" "node_name" {
  count = var.vm_count
  keepers = {
    vm_count = var.vm_count
  }
}

locals {
  vm_names = [for i in range(var.vm_count) : format("%s-%s-%s", var.cluster_name, var.role, random_pet.node_name[i].id)]
}

resource "proxmox_virtual_environment_vm" "vm" {
  count       = var.vm_count
  name        = local.vm_names[count.index]
  node_name   = var.proxmox_node_name
  description = format("Talos %s node %d for %s", title(var.role), count.index, var.cluster_name)
  tags        = ["kubernetes", "talos", var.role]
  pool_id     = "k8s-${var.role}"

  clone {
    vm_id     = 106
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

  lifecycle {
    create_before_destroy = true
  }
}
