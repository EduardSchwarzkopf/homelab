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
  port      = var.postgres_port
  username  = var.postgres_user
  password  = var.postgres_password
  sslmode   = "disable"
  superuser = true
}
