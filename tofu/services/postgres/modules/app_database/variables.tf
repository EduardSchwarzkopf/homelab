variable "app_name" {
  description = "Name of the application (prefix for user and database)"
  type        = string
}

variable "password" {
  description = "Password for the PostgreSQL user"
  type        = string
  sensitive   = true
}
