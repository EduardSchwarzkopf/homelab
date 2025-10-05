output "hostname" {
  value = local.vm_name
}

output "postgres_user" {
  value = local.postgres_user
}

output "postgres_port" {
  value = local.postgres_port
}

output "id" {
  value = module.server.vm_id
}
