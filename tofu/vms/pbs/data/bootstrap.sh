
OS=$(lsb_release -cs)

sudo tee /etc/apt/sources.list.d/proxmox.sources > /dev/null <<EOT
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: $OS
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOT

wget https://enterprise.proxmox.com/debian/proxmox-archive-keyring-$OS.gpg -O /usr/share/keyrings/proxmox-archive-keyring.gpg

apt update
chown -R backup:backup /etc/proxmox-backup/
chmod 700 /etc/proxmox-backup/

DEBIAN_FRONTEND=noninteractive apt install proxmox-backup-server -y
