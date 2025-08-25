module "kubernetes_csi_user" {
  source = "./modules/proxmox_automation_user"

  user_config = {
    user     = "kubernetes_csi"
    password = var.iac_user_password
    privileges = [
      "VM.Monitor",
      "VM.Config.Disk",
      "Datastore.Allocate",
      "Datastore.AllocateSpace",
      "Datastore.Audit",
    ]
  }
}
