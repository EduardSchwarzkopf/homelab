module "app_database" {
  source = "./modules/app_database"
  databases = [
    {
      app_name = "plane",
      password = var.plane_db_password
    },
    {
      app_name = "paperless",
      password = var.paperless_db_password
    },
    {
      app_name = "artifactory",
      password = var.artifactory_db_password
    }
  ]
}
