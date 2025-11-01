#!/bin/bash


echo '> Creating cleanup script ...'
sudo cat <<EOF > /tmp/cleanup.sh
#!/bin/bash

# Cleans all audit logs.
echo '> Cleaning all audit logs ...'
if [ -f /var/log/audit/audit.log ]; then
cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
cat /dev/null > /var/log/lastlog
fi

# Cleans persistent udev rules.
echo '> Cleaning persistent udev rules ...'
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleans /tmp directories.
echo '> Cleaning /tmp directories ...'
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleans SSH keys.
echo '> Cleaning SSH keys ...'
rm -f /etc/ssh/ssh_host_*

# Sets hostname to localhost.
echo '> Setting hostname to localhost ...'
cat /dev/null > /etc/hostname
hostnamectl set-hostname localhost

# Cleans apt-get.
echo '> Cleaning apt-get ...'
apt-get clean
apt-get autoremove


# Cleans the machine-id.
echo '> Cleaning the machine-id ...'
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Cleans shell history.
echo '> Cleaning shell history ...'
unset HISTFILE
history -cw
echo > ~/.bash_history
rm -rf /root/.bash_history

# Cloud Init Nuclear Option
rm -rf /etc/cloud/cloud-init.disabled
rm -rf /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -rf /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -rf /etc/cloud/cloud.cfg.d/90-installer-network.cfg
rm -rf /etc/netplan/50-cloud-init.yaml
rm -rf /etc/ssh/sshd_config.d/50-cloud-init.conf
rm -rf /etc/netplan/00-installer-config.yaml
EOF


echo '> Changeing script permissions for execution ...'
sudo chmod +x /tmp/cleanup.sh

echo '> Executing the cleanup script ...'
sudo /tmp/cleanup.sh
sudo rm -rf /tmp/cleanup.sh

echo '> Disable systemd-networkd-wait-online'
sudo systemctl disable systemd-networkd-wait-online.service

echo '> Disable root'
sudo passwd -d root
sudo passwd -l root

echo '> Done.'  
