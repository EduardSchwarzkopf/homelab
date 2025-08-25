
resource "terraform_data" "wait_for_db_vm" {
  depends_on = [module.vm-postgres]

  triggers_replace = {
    vm_id = module.vm-postgres.id
  }

  provisioner "local-exec" {
    command = "sleep 500"
  }
}

module "postgres" {
  depends_on = [terraform_data.wait_for_db_vm]
  source     = "./services/postgres"

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
