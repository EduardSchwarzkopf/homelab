locals {
  apps = {
    docmost = {
      create_database = true
      proxy = {
        domain_names = ["docmost.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 8081
      }
    }
    plane = {
      create_database = true
      proxy = {
        domain_names = ["plane.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 8081
      }
    }
    fritz = {
      create_database = false
      proxy = {
        domain_names = ["fritz.${local.lan_domain}"]
        forward_host = "192.168.178.1"
        forward_port = 80
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
    pihole = {
      create_database = false
      proxy = {
        domain_names = ["pihole.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 8443
      }
    }
    proxmox = {
      create_database = false
      proxy = {
        domain_names     = ["proxmox.${local.lan_domain}"]
        use_https_scheme = true
        forward_host     = "192.168.178.10"
        forward_port     = 8006
      }
    }
    vault = {
      create_database = false
      proxy = {
        domain_names     = ["vault.${local.lan_domain}"]
        forward_host     = local.pihole_ip
        forward_port     = 8200
        use_https_scheme = true
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
    printer = {
      create_database = false
      proxy = {
        domain_names = ["printer.${local.local_domain}"]
        forward_host = "192.168.178.106"
        forward_port = 80
      }
    }
    nginx-proxy-manager = {
      create_database = false
      proxy = {
        domain_names = ["npm.${local.lan_domain}"]
        forward_host = local.pihole_ip
        forward_port = 81
      }
    }
  }

  db_apps = { for k, v in local.apps : k => v if v.create_database }
}
