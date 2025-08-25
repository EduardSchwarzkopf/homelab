
resource "pihole_dns_record" "homeserver" {
  domain = local.homeserver_hostname
  ip     = "192.168.178.10"
}
