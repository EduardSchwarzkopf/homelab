variable "host" {
  description = "IP or hostname of the target VM"
  type        = string
}

variable "user" {
  description = "SSH username"
  type        = string
}

variable "cron_name" {
  description = "Filename for the cron entry (e.g., shutdown_midnight)"
  type        = string
}

variable "cron_schedule" {
  description = "Cron schedule"
  type        = string
}

variable "command" {
  description = "Cron command without the filename"
  type        = string
}

variable "run_as_user" {
  type        = string
  description = "The user to run the cronjob as"
}
