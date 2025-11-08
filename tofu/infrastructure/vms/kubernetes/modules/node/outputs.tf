output "hostnames" {
  description = "List of VM DNS hostnames (Proxmox VM names)"
  value       = toset(keys(data.dns_a_record_set.this))
}
