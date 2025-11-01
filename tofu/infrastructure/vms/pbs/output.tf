output "hostname" {
  value = local.vm_name
}

output "id" {
  value = module.server.vm_id
}
