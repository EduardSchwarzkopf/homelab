#!/bin/bash
set -euo pipefail

# Check if OS is Ubuntu or Debian
if ! grep -Eqi 'ubuntu|debian' /etc/os-release; then
  echo "Not Ubuntu or Debian. Exiting."
  exit 0
fi

# Find root mount device (LV or partition)
ROOT_DEV=$(findmnt -n -o SOURCE /)

# Check if root is on LVM
if [[ "$ROOT_DEV" =~ /dev/mapper/ || "$ROOT_DEV" =~ /dev/*-vg/*-lv ]]; then
  echo "LVM setup detected on root device: $ROOT_DEV"
  
  # LVM setup
  LV_PATH="$ROOT_DEV"
  VG_NAME=$(lvs --noheadings -o vg_name "$LV_PATH" | awk '{print $1}')
  
  # Get the PV device backing the LV
  PV_PATH=$(pvs --noheadings -o pv_name --select vg_name="$VG_NAME" | awk '{print $1}' | head -n1)
  
  if [[ ! $PV_PATH =~ ^/dev/ ]]; then
    echo "Could not determine PV device. Exiting."
    exit 1
  fi
  
  # Parse disk and partition number from PV device (e.g., /dev/sda5)
  DISK=$(lsblk -no PKNAME "$PV_PATH" | head -n1)
  DISK="/dev/$DISK"
  PARTNUM=$(echo "$PV_PATH" | grep -o '[0-9]*$')
  
  # Check if there is free space on the disk
  DISK_SIZE=$(lsblk -b -dn -o SIZE "$DISK")
  PART_SIZE=$(lsblk -b -dn -o SIZE "$PV_PATH")
  
  if [ "$DISK_SIZE" -le "$PART_SIZE" ]; then
    echo "No unallocated space to grow into. Exiting."
    exit 0
  fi
  
  echo "Free space detected. Proceeding with resize..."
  
  # Check if this is an extended partition setup (partition 5+ indicates logical partition)
  if [ "$PARTNUM" -ge 5 ]; then
    echo "Detected logical partition inside extended partition."
    
    # Disable swap
    echo "Disabling swap..."
    swapoff -a || true
    
    # Rescan the disk
    echo "Rescanning the disk..."
    echo 1 > /sys/class/block/$(basename "$DISK")/device/rescan || true
    
    # Get extended partition number (usually 2)
    EXT_PART=$(parted -s "$DISK" print | grep extended | awk '{print $1}')
    
    if [ -z "$EXT_PART" ]; then
      echo "Could not find extended partition. Falling back to standard method."
    else
      echo "Printing current partition layout..."
      parted --script "$DISK" unit s print
      
      echo "Expanding extended partition ${EXT_PART} to fill disk..."
      parted --script "$DISK" resizepart $EXT_PART 100%
      
      echo "Expanding logical partition ${PARTNUM} inside extended container..."
      parted --script "$DISK" resizepart $PARTNUM 100%
      
      echo "Informing kernel to re-read partition table..."
      partprobe "$DISK"
    fi
  else
    # Standard partition (not in extended partition)
    # Ensure growpart is available
    if ! command -v growpart >/dev/null 2>&1; then
      echo "Installing cloud-guest-utils for growpart..."
      apt-get update
      apt-get install -y cloud-guest-utils
    fi
    
    echo "Growing partition $DISK $PARTNUM..."
    growpart "$DISK" "$PARTNUM"
  fi
  
  echo "Resizing physical volume $PV_PATH..."
  pvresize "$PV_PATH"
  
  echo "Extending LV $LV_PATH to use all free space..."
  lvextend -r -l +100%FREE "$LV_PATH"
  
  # Re-enable swap
  echo "Re-enabling swap (if configured)..."
  swapon -a || true
  
  echo "LVM root disk successfully grown to 100% of available space."
  
else
  # Non-LVM setup (fallback)
  echo "Non-LVM setup detected on root device: $ROOT_DEV"
  
  DISK=$(lsblk -no PKNAME "$ROOT_DEV" | head -n1)
  DISK="/dev/$DISK"
  PARTNUM=$(echo "$ROOT_DEV" | grep -o '[0-9]*$')
  
  DISK_SIZE=$(lsblk -b -dn -o SIZE "$DISK")
  PART_SIZE=$(lsblk -b -dn -o SIZE "$ROOT_DEV")
  
  if [ "$DISK_SIZE" -le "$PART_SIZE" ]; then
    echo "No unallocated space to grow into. Exiting."
    exit 0
  fi
  
  if ! command -v growpart >/dev/null 2>&1; then
    echo "Installing cloud-guest-utils for growpart..."
    apt-get update
    apt-get install -y cloud-guest-utils
  fi
  
  echo "Growing partition $DISK $PARTNUM..."
  growpart "$DISK" "$PARTNUM"
  
  FSTYPE=$(lsblk -no FSTYPE "$ROOT_DEV")
  
  if [ "$FSTYPE" = "ext4" ]; then
    echo "Resizing ext4 filesystem..."
    resize2fs "$ROOT_DEV"
  elif [ "$FSTYPE" = "xfs" ]; then
    echo "Resizing xfs filesystem..."
    xfs_growfs /
  else
    echo "Unsupported filesystem: $FSTYPE. Exiting."
    exit 1
  fi
  
  echo "Root disk successfully grown to 100% of available space."
fi

echo "Done. Disk resize complete."