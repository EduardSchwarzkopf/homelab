locals {
  shutdown_command  = "/sbin/shutdown -h now"
  wakeonlan_command = "wakeonlan ${var.homeserver_mac}"
  shutdown_as_user  = "root"
}

module "shutdown_weekdays" {
  source        = "../modules/cron_remote"
  host          = local.homeserver_hostname
  user          = var.node_ssh_user
  cron_name     = "shutdown_weekdays"
  cron_schedule = "30 23 * * 1-5"
  run_as_user   = local.shutdown_as_user
  command       = local.shutdown_command
}

module "shutdown_weekends" {
  source        = "../modules/cron_remote"
  host          = local.homeserver_hostname
  user          = var.node_ssh_user
  cron_name     = "shutdown_weekdays"
  cron_schedule = "0 1 * * 6,0"
  run_as_user   = local.shutdown_as_user
  command       = local.shutdown_command
}

module "wakeonlan_weekdays" {
  source        = "../modules/cron_remote"
  host          = var.wakeonlan_host
  user          = var.wakeonlan_ssh_user
  cron_name     = "wakeonlan_weekdays"
  cron_schedule = "30 6 * * 1-5"
  run_as_user   = var.wakeonlan_ssh_user
  command       = local.wakeonlan_command
}

module "wakeonlan_weekends" {
  source        = "../modules/cron_remote"
  host          = var.wakeonlan_host
  user          = var.wakeonlan_ssh_user
  cron_name     = "wakeonlan_weekends"
  cron_schedule = "0 8 * * 6,0"
  run_as_user   = var.wakeonlan_ssh_user
  command       = local.wakeonlan_command
}
