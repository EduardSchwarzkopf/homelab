
resource "terraform_data" "wait_for_db_vm" {
  depends_on = [module.vm-postgres]

  triggers = {
    vm_id = module.vm-postgres.id
  }

  provisioner "local-exec" {
    command = "sleep 180"
  }
}

module "postgres" {
  source            = "./services/postgres"
  postgres_user     = module.vm-postgres.postgres_user
  postgres_password = var.postgres_password
  postgres_host     = module.vm-postgres.hostname
  postgres_port     = module.vm-postgres.postgres_port

  plane_db_password     = var.plane_db_password
  paperless_db_password = var.paperless_db_password
}


variable "plane_db_password" {
  type      = string
  sensitive = true
}

variable "paperless_db_password" {
  type      = string
  sensitive = true
}
