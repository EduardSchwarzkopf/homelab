variable "proxmox_node_name" {
  description = "Name of the Proxmox node"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "role" {
  description = "Role of the server (for description)"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = []
}

variable "clone_vm_id" {
  description = "Source VM ID to clone from"
  type        = number
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Memory in GB"
  type        = number
  default     = 2
}

variable "os_disk_datastore_id" {
  description = "Datastore for OS disk"
  type        = string
}

variable "os_disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 20
}

variable "cloud_init" {
  description = "Cloud-init configuration object"
  type = object({
    packages = list(string)
    write_files = list(object({
      path        = string
      content     = string
      owner       = string
      permissions = string
      encoding    = optional(string)
      defer       = optional(bool, false)
    }))
    bootstrap_script = string
  })
}

variable "data_disk" {
  description = "Single data disk configuration for the VM"
  type = object({
    datastore_id      = string
    size              = number
    file_format       = optional(string)
    path_in_datastore = optional(string)
    mount_path        = string
  })
  default = {
    datastore_id      = null
    size              = null
    file_format       = null
    path_in_datastore = null
    mount_path        = null
  }
}

variable "cloud_config_debug" {
  description = "If true, write the rendered cloud-config to a local debug file"
  type        = bool
  default     = false
}
