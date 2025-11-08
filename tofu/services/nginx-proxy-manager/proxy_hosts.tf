locals {
  pihole_ip    = "192.168.178.53"
  local_tld    = "lan"
  lan_domain   = "${local.local_tld}.schwarzkopf.center"
  local_domain = "home.${local.local_tld}"
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
        "paperless.${local.lan_domain}",
        "assistant.${local.lan_domain}"
      ]
      forward_host = "192.168.178.240"
      forward_port = 443
    },
    {
      domain_names     = ["artifactory.${local.lan_domain}"]
      use_https_scheme = false
      forward_host     = "artifactory.${local.local_tld}"
      forward_port     = 8082
    },
    {
      domain_names     = ["fritz.${local.lan_domain}"]
      use_https_scheme = false
      forward_host     = "192.168.178.1"
      forward_port     = 80
    },
    {
      domain_names     = ["homebox.${local.lan_domain}"]
      use_https_scheme = false
      forward_host     = local.pihole_ip
      forward_port     = 3100
    },
    {
      domain_names     = ["npm.${local.lan_domain}"]
      use_https_scheme = false
      forward_host     = local.pihole_ip
      forward_port     = 81
    },
    {
      domain_names   = ["pbs.${local.lan_domain}"]
      forward_host   = "proxmox-backup-server.${local.local_tld}"
      forward_port   = 8007
      block_exploits = false
    },
    {
      domain_names     = ["pgadmin.${local.lan_domain}"]
      use_https_scheme = false
      forward_host     = "database-pg-prod.${local.local_tld}"
      forward_port     = 80
    },
    {
      domain_names = ["pihole.${local.lan_domain}"]
      forward_host = local.pihole_ip
      forward_port = 8443
    },
    {
      domain_names = ["plane.${local.lan_domain}"]
      forward_host = local.pihole_ip
      forward_port = 8081
    },
    {
      domain_names = ["proxmox.${local.lan_domain}"]
      forward_host = "192.168.178.10"
      forward_port = 8006
    },
    {
      domain_names = ["vault.${local.lan_domain}"]
      forward_host = local.pihole_ip
      forward_port = 8200
    },
    {
      domain_names     = ["printer.${local.local_domain}"]
      use_https_scheme = false
      forward_host     = "192.168.178.106"
      forward_port     = 80
    },
  ]
}
