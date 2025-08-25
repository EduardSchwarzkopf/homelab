
resource "pihole_dns_record" "homeserver" {
  domain = var.proxmox_node_name
  ip     = "192.168.178.10"
}
