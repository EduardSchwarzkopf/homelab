variable "postgres_host" {
  description = "Hostname or IP address of the PostgreSQL server"
  type        = string
}

variable "postgres_port" {
  description = "Port of the PostgreSQL server"
  type        = number
  default     = 5432
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}
