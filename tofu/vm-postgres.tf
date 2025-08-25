module "vm-postgres" {
  source            = "./vms/postgres"
  postgres_password = var.postgres_password
  pgadmin_email     = var.pgadmin_email
  pgadmin_password  = var.pgadmin_password
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "pgadmin_email" {
  type      = string
  sensitive = true
}

variable "pgadmin_password" {
  type      = string
  sensitive = true
}
