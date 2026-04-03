locals {
  npm_certificate_id = 99
  pihole_ip          = "192.168.178.53"
  local_tld          = "lan"
  lan_domain         = "${local.local_tld}.schwarzkopf.center"
  local_domain       = "home.${local.local_tld}"
  postgres_host      = "database-pg-prod.${local.local_tld}"
}
