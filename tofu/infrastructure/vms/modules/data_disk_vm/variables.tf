variable "consumer_vm_name" {
  description = "Name of the VM actually using the disk"
  type        = string
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "size" {
  description = "Size of the data disk in GB"
  type        = number
}

variable "backup_tier" {
  description = "Backup tier for this data disk. Options: 0 (No Backup), 1 (Critical), 2 (Standard), 3 (Development), 4 (Cache)"
  type        = number

  validation {
    condition     = contains([0, 1, 2, 3, 4], var.backup_tier)
    error_message = "backup_tier must be one of: 0 (No Backup),  1 (Critical), 2 (Standard), 3 (Development), 4 (Cache)"
  }
}

variable "additional_tags" {
  description = "Additional tags to add to the data disk VM"
  type        = list(string)
  default     = []
}

variable "datastore_id" {
  description = "The datastore to place the disk onto"
  type        = string
  default     = "zfs-longhorn"
}
