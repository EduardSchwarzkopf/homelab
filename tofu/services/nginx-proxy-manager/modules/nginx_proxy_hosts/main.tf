resource "nginxproxymanager_proxy_host" "host" {
  for_each = { for idx, host in var.proxy_hosts : idx => host }

  domain_names   = each.value.domain_names
  forward_scheme = each.value.forward_scheme
  forward_host   = each.value.forward_host
  forward_port   = each.value.forward_port
  certificate_id = var.credential_id

  caching_enabled         = true
  allow_websocket_upgrade = true
  block_exploits          = true

  ssl_forced      = true
  hsts_enabled    = true
  hsts_subdomains = false
  http2_support   = true
}
