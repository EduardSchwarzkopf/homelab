
variable "postgres_host" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "plane_db_password" {
  type      = string
  sensitive = true
}

variable "paperless_db_password" {
  type      = string
  sensitive = true
}

variable "artifactory_db_password" {
  type      = string
  sensitive = true
}
