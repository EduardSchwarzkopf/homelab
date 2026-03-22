locals {

  application_name = "docmost"
  mount_path       = "/mnt/${local.application_name}"

  vm_name = local.application_name
}
