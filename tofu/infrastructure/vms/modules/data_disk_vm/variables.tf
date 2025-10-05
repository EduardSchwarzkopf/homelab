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

variable "additional_tags" {
  description = "Additional tags to add to the data disk VM"
  type        = list(string)
  default     = []
}
