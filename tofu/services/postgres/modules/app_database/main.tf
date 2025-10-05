terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}

locals {
  db_map_nonsensitive = nonsensitive({
    for db in var.databases : db.app_name => db
  })
}

resource "postgresql_role" "app_user" {
  for_each = local.db_map_nonsensitive
  name     = each.value.app_name
  login    = true
  password = each.value.password
}

resource "postgresql_database" "app_db" {
  for_each = local.db_map_nonsensitive
  name     = each.value.app_name
  owner    = postgresql_role.app_user[each.key].name
  lifecycle {
    prevent_destroy = true
  }
}

resource "postgresql_grant" "app_privileges" {
  for_each    = local.db_map_nonsensitive
  database    = postgresql_database.app_db[each.key].name
  role        = postgresql_role.app_user[each.key].name
  schema      = "public"
  object_type = "database"
  privileges  = ["ALL"]
}
