locals {
  # Build metadata
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  timestamp         = timestamp()
  build_date        = formatdate("DD-MM-YYYY hh:mm ZZZ", local.timestamp)
  build_version     = formatdate("YYYYMMDD", local.timestamp)
  os_family         = "linux"
  build_description = <<-EOF
Version: ${local.build_version}

Built on: ${local.build_date}

OS: ${var.os} ${var.os_version}

${local.build_by}
EOF

  # VM name
  formatted_os_version = replace(var.os_version, ".", "-")
  vm_name              = "${local.os_family}-${var.os}-${local.formatted_os_version}"

  # Per-OS configuration map
  cfg_map = {
    ubuntu = {
      iso_file = "ubuntu-${var.os_version}-live-server-amd64.iso"
      iso_checksums = {
        "24.04.2" = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
        "24.04.3" = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
      }
      boot_command = [
        "c<wait> ",
        "linux /casper/vmlinuz ipv6.disable=1 --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
        "<enter><wait5s>",
        "initrd /casper/initrd",
        "<enter><wait5s>",
        "boot",
        "<enter>"
      ]
      ssh_username = "ubuntu"
      ssh_password = "ubuntu"
      env          = {}
    }
    talos = {
      iso_file = "archlinux-2025.07.01-x86_64.iso"
      iso_checksums = {
        "1.10.5" = "sha256:0dbac20eddeef67d3b3e9c109a51b77140cf4ee33cc0b408181454f6c41d0a91"
      }
      additional_iso_files = []
      boot_command = [
        "<enter><wait1m>",
        "passwd<enter><wait>packer<enter><wait>packer<enter>"
      ]
      ssh_username = "root"
      ssh_password = "packer"
      env = {
        OS_VERSION = var.os_version
      }
    }
  }

  # Lookup the config for the given OS
  cfg = local.cfg_map[var.os]

  # ISO checksum lookup (default to UNKNOWN if not defined)
  iso_checksum = lookup(local.cfg.iso_checksums, var.os_version, "sha256:UNKNOWN")
}

source "proxmox-iso" "vm" {
  proxmox_url              = "https://${var.proxmox_hostname}/api2/json"
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = false

  http_port_min = 8500
  http_port_max = 8505

  vm_name              = local.vm_name
  tags                 = "template;${local.os_family};${var.os}"
  node                 = "homeserver"
  template_name        = "${local.vm_name}-${local.build_version}"
  template_description = local.build_description

  cpu_type = "x86-64-v2-AES"
  sockets  = 1
  cores    = 2
  memory   = 2048

  disks {
    disk_size    = "10G"
    type         = "scsi"
    storage_pool = "vm-os-pool"
    format       = "raw"
  }

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  os              = "l26"
  scsi_controller = "virtio-scsi-pci"
  onboot          = true
  qemu_agent      = true

  boot_iso {
    iso_file          = "local:iso/${local.cfg.iso_file}"
    unmount           = true
    iso_checksum      = local.iso_checksum
    keep_cdrom_device = false
  }

  cloud_init              = true
  cloud_init_storage_pool = "vm-os-pool"

  boot         = "order=scsi0;ide2;net0"
  boot_wait    = "5s"
  boot_command = local.cfg.boot_command

  http_directory = "${path.cwd}/http/${var.os}"

  ssh_username = local.cfg.ssh_username
  ssh_password = local.cfg.ssh_password
  communicator = "ssh"
  ssh_timeout  = "15m"
}

build {
  sources = ["source.proxmox-iso.vm"]

  provisioner "shell" {
    env     = local.cfg.env
    scripts = ["${path.cwd}/scripts/${var.os}.sh"]
  }
}
