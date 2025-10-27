output "proxy_hosts_ids" {
  value = { for idx, host in nginxproxymanager_proxy_host.host : idx => host.id }
}
