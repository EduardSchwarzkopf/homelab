locals {
  application_name = "ollama"
  vm_name          = local.application_name
  mount_path       = "/mnt/${local.application_name}"
}
