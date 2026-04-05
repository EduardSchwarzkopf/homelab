locals {
  apps = {
    plane = {
      create_database = false
      proxy = {
        domain_names = ["plane.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 8081
      }
    }
    paperless = {
      create_database = true
      proxy = {
        domain_names = ["paperless.${local.lan_domain}"]
        forward_host = "paperless.${local.local_tld}"
        forward_port = 80
      }
    }
    homebox = {
      create_database = false
      proxy = {
        domain_names = ["homebox.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 3100
      }
    }
    proxmox-backup-server = {
      create_database = false
      proxy = {
        domain_names   = ["pbs.${local.lan_domain}", "proxmox-backup-server.${local.lan_domain}"]
        forward_host   = "proxmox-backup-server.${local.local_tld}"
        forward_port   = 8007
        block_exploits = false
      }
    }
    pgadmin = {
      create_database = false
      proxy = {
        domain_names = ["pgadmin.${local.lan_domain}"]
        forward_host = local.postgres_host
        forward_port = 80
      }
    }
    immich = {
      create_database = true
      proxy = {
        domain_names = ["immich.${local.lan_domain}"]
        forward_host = "immich.${local.local_tld}"
        forward_port = 2283
      }
    }
  }

  db_apps = { for k, v in local.apps : k => v if v.create_database }
}
