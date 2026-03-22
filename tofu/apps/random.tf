resource "random_password" "app_database" {
  for_each = local.db_apps
  length   = 32
  special  = true
}
