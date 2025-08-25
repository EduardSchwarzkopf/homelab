locals {
  timeout             = "30s"
  cron_d_path         = local.cron_d_path
  reload_cron_command = "sudo systemctl reload cron || sudo service cron reload"
}

resource "ssh_resource" "cron" {
  host    = var.host
  user    = var.user
  agent   = true
  timeout = local.timeout

  triggers = {
    cron = "${var.cron_schedule} ${var.run_as_user} ${var.command}"
  }

  commands = [
    <<-EOT
    echo "${var.cron_schedule} ${var.run_as_user} ${var.command}" | sudo tee ${local.cron_d_path}/${var.cron_name}
EOT
    ,
    "sudo chmod 644 ${local.cron_d_path}/${var.cron_name}",
    local.reload_cron_command
  ]
}

resource "ssh_resource" "cron_destroy" {
  host    = var.host
  user    = var.user
  agent   = true
  timeout = local.timeout

  when = "destroy"

  commands = [
    "sudo rm -f ${local.cron_d_path}/${var.cron_name}",
    local.reload_cron_command
  ]
}
