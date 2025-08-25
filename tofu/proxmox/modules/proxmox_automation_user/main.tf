variable "user_config" {
  type = object({
    user : string
    password : string
    privileges : list(string)
    acls : optional(list(object({
      path : string
      propagate : bool
      role_id : string
    })), [])
  })
}

resource "proxmox_virtual_environment_role" "default_role" {
  role_id    = var.user_config.user
  privileges = var.user_config.privileges
}

resource "proxmox_virtual_environment_user" "automation_user" {
  depends_on = [proxmox_virtual_environment_role.default_role]
  user_id    = "${var.user_config.user}@pve"
  password   = var.user_config.password

  acl {
    path      = "/"
    propagate = true
    role_id   = var.user_config.user
  }

  dynamic "acl" {
    for_each = var.user_config.acls
    content {
      path      = acl.value.path
      propagate = acl.value.propagate
      role_id   = acl.value.role_id
    }
  }
}

resource "proxmox_virtual_environment_user_token" "automation_token" {
  token_name            = "token"
  user_id               = proxmox_virtual_environment_user.automation_user.user_id
  privileges_separation = false
}
