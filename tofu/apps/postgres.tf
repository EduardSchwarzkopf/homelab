
resource "postgresql_role" "app_user" {
  for_each = local.db_apps
  name     = each.key
  login    = true
  password = random_password.app_database[each.key].result
}

resource "postgresql_database" "app_db" {
  for_each = local.db_apps
  name     = each.key
  owner    = postgresql_role.app_user[each.key].name
  lifecycle {
    prevent_destroy = false
  }
}

resource "postgresql_grant" "app_privileges" {
  for_each    = local.db_apps
  database    = postgresql_database.app_db[each.key].name
  role        = postgresql_role.app_user[each.key].name
  schema      = "public"
  object_type = "database"
  privileges  = ["ALL"]
}

