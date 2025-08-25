variable "proxmox_node_name" {
  type = string

}

variable "role" {
  description = "Role of the VM (either 'controlplane' or 'worker')"
  type        = string

  validation {
    condition     = contains(["controlplane", "worker"], var.role)
    error_message = "The role must be either 'controlplane' or 'worker'."
  }
}

variable "cluster_name" {
  description = "The cluster name used in naming VMs"
  type        = string
  default     = "homelab"
}

variable "vm_id_start" {
  description = "Starting VM ID to avoid conflicts"
  type        = number
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory size in Gb. Must be at least 2."
  type        = number
  default     = 2

  validation {
    condition     = var.memory >= 2
    error_message = "Memory must be at least 2 GB."
  }
}


variable "cpu_cores" {
  description = "CPU cores. Must be at least 2"
  type        = number
  default     = 4

  validation {
    condition     = var.cpu_cores >= 2
    error_message = "CPU must be at least 2."
  }
}

variable "disk_size" {
  description = "Disk size in GB. Must be at least 10."
  type        = number
  default     = 10

  validation {
    condition     = var.disk_size >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}
