resource "nginxproxymanager_proxy_host" "host" {
  for_each = { for k, v in local.apps : k => v.proxy }

  domain_names   = each.value.domain_names
  forward_scheme = try(each.value.use_https_scheme, false) ? "https" : "http"
  forward_host   = each.value.forward_host
  forward_port   = each.value.forward_port
  certificate_id = local.npm_certificate_id

  caching_enabled         = true
  allow_websocket_upgrade = true
  block_exploits          = try(each.value.block_exploits, true)
  ssl_forced              = true
  hsts_enabled            = true
  hsts_subdomains         = false
  http2_support           = true
}
