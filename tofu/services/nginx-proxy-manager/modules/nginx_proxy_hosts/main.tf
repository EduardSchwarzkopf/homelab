resource "nginxproxymanager_proxy_host" "host" {
  # Use stable identifiers based on domain names to prevent resource shifting
  # when entries are added/removed from the list
  for_each = {
    for host in var.proxy_hosts :
    join("_", host.domain_names) => host
  }

  domain_names   = each.value.domain_names
  forward_scheme = each.value.use_https_scheme ? "https" : "http"
  forward_host   = each.value.forward_host
  forward_port   = each.value.forward_port
  certificate_id = var.certificate_id

  caching_enabled         = true
  allow_websocket_upgrade = true
  block_exploits          = each.value.block_exploits

  ssl_forced      = true
  hsts_enabled    = true
  hsts_subdomains = false
  http2_support   = true
}
