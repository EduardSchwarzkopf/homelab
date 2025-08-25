output "vm_hostnames" {
  description = "List of VM DNS hostnames (Proxmox VM names)"
  value       = sort(keys(data.dns_a_record_set.this))
}

output "vm_ips" {
  description = "Primary IPv4 address for each node"
  value = [
    for name in sort(keys(data.dns_a_record_set.this)) :
    data.dns_a_record_set.this[name].addrs[0]
  ]
}

output "vm_map" {
  description = "Map of hostname → primary IPv4 address"
  value = {
    for name, rec in data.dns_a_record_set.this :
    name => rec.addrs[0]
  }
}
