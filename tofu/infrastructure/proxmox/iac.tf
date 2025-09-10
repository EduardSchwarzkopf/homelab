module "iac_user" {
  source = "./modules/proxmox_automation_user"

  user_config = {
    user     = "iac"
    password = var.iac_user_password
    privileges = [
      "Sys.Modify",
      "Permissions.Modify"
    ]
    acls = [
      {
        path      = "/"
        propagate = true
        role_id   = "PVEAdmin"
      }
    ]
  }
}
