module "packer_user" {
  source = "./modules/proxmox_automation_user"

  user_config = {
    user     = "packer"
    password = var.packer_user_password
    privileges = [
      "VM.Allocate",
      "VM.Config.CPU",
      "VM.Config.Disk",
      "VM.Config.Memory",
      "VM.Config.Network",
      "VM.PowerMgmt",
      "VM.Monitor",
      "VM.Snapshot",
      "VM.Migrate",
      "Datastore.AllocateSpace",
      "Sys.Audit",
      "Sys.Console"
    ]
  }
}
