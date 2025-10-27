locals {
  pihole_ip    = "192.168.178.53"
  lan_domain   = "lan.schwarzkopf.center"
  local_domain = "home.lan"
}

module "nginx_hosts" {
  source        = "./modules/nginx_proxy_hosts"
  credential_id = nginxproxymanager_certificate_letsencrypt.lan_schwarzkopf_center.id

  proxy_hosts = [
    {
      domain_names = [
        "argocd.${local.local_domain}",
        "argocd.${local.lan_domain}",
        "longhorn.${local.local_domain}",
        "longhorn.${local.lan_domain}",
        "paperless.${local.lan_domain}"
      ]
      forward_scheme = "https"
      forward_host   = "192.168.178.240"
      forward_port   = 443
    },
    {
      domain_names   = ["artifactory.${local.lan_domain}"]
      forward_scheme = "http"
      forward_host   = "artifactory.lan"
      forward_port   = 8082
    },
    {
      domain_names   = ["fritz.${local.lan_domain}"]
      forward_scheme = "http"
      forward_host   = "192.168.178.1"
      forward_port   = 80
    },
    {
      domain_names   = ["homebox.${local.lan_domain}"]
      forward_scheme = "http"
      forward_host   = local.pihole_ip
      forward_port   = 3100
    },
    {
      domain_names   = ["npm.${local.lan_domain}"]
      forward_scheme = "http"
      forward_host   = local.pihole_ip
      forward_port   = 81
    },
    {
      domain_names   = ["pbs.${local.lan_domain}"]
      forward_scheme = "https"
      forward_host   = "proxmox-backup-server.lan"
      forward_port   = 8007
    },
    {
      domain_names   = ["pgadmin.${local.lan_domain}"]
      forward_scheme = "http"
      forward_host   = "database-pg-prod.lan"
      forward_port   = 80
    },
    {
      domain_names   = ["pihole.${local.lan_domain}"]
      forward_scheme = "https"
      forward_host   = local.pihole_ip
      forward_port   = 8443
    },
    {
      domain_names   = ["plane.${local.lan_domain}"]
      forward_scheme = "https"
      forward_host   = local.pihole_ip
      forward_port   = 8081
    },
    {
      domain_names   = ["proxmox.${local.lan_domain}"]
      forward_scheme = "https"
      forward_host   = "192.168.178.10"
      forward_port   = 8006
    },
    {
      domain_names   = ["vault.${local.lan_domain}"]
      forward_scheme = "https"
      forward_host   = local.pihole_ip
      forward_port   = 8200
    }
  ]
}

resource "nginxproxymanager_proxy_host" "printer" {

  domain_names   = ["printer.${local.local_domain}"]
  forward_scheme = "http"
  forward_host   = "192.168.178.106"
  forward_port   = 80

  caching_enabled         = true
  allow_websocket_upgrade = true
  block_exploits          = true
}
