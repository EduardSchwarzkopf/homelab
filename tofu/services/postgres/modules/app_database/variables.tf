variable "databases" {
  description = "List of app databases to create. Each object must have app_name and password."
  type = list(object({
    app_name = string
    password = string
  }))
  sensitive = true
}
