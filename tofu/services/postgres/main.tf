module "plane_db" {
  source   = "./modules/app_database"
  app_name = "plane"
  password = var.plane_db_password
}

module "paperless_db" {
  source   = "./modules/app_database"
  app_name = "paperless"
  password = var.paperless_db_password
}

