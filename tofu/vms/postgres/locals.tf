locals {
  node_name          = "homeserver"
  vm_name            = "database-pg-prod"
  mount_path         = "/mnt/data"
  postgres_data_path = "${local.mount_path}/pgdata"
  pgadmin_data_path  = "${local.mount_path}/pgadmin"

  postgres_user = "postgres"
  postgres_port = 5432

}
