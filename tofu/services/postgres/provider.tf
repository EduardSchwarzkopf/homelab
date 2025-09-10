terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

provider "postgresql" {
  host      = var.postgres_host
  port      = 5432
  username  = "postgres"
  password  = var.postgres_password
  sslmode   = "disable"
  superuser = true
}
