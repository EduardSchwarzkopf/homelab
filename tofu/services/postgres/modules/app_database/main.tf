terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}

resource "postgresql_role" "app_user" {
  name     = var.app_name
  login    = true
  password = var.password
}

resource "postgresql_database" "app_db" {
  name  = var.app_name
  owner = postgresql_role.app_user.name
  lifecycle {
    prevent_destroy = true
  }
}

resource "postgresql_grant" "app_privileges" {
  database    = postgresql_database.app_db.name
  role        = postgresql_role.app_user.name
  schema      = "public"
  object_type = "database"
  privileges  = ["ALL"]
}
