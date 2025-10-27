variable "os" {
  type        = string
  description = "Either \"talos\", \"debian\" or \"ubuntu\""

  validation {
    condition     = contains(["talos", "ubuntu", "debian"], var.os)
    error_message = "The \"os\" variable must be either \"talos\", \"debian\" or \"ubuntu\"."
  }
}

variable "os_version" {
  type        = string
  description = "Version string for the selected OS (e.g. 24.04.2 for Ubuntu)."
  default     = ""
}

variable "proxmox_hostname" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}
