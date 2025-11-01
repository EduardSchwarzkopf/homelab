#!/bin/bash
set -e

# Usage: mount-additional-disks.sh <scsi_number1> <mount_path1> [<scsi_number2> <mount_path2> ...]

if (( $# % 2 != 0 )); then
  echo "Usage: $0 <scsi_number1> <mount_path1> [<scsi_number2> <mount_path2> ...]"
  exit 1
fi

while (( "$#" )); do
  SCSI_NUM="$1"
  MOUNT_PATH="$2"
  shift 2

  DEV="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi${SCSI_NUM}"

  if [ ! -b "$DEV" ]; then
    echo "Device for SCSI $SCSI_NUM not found at $DEV. Skipping $MOUNT_PATH."
    continue
  fi

  # Find first partition, or create one if none exists
  PART=""
  PARTS=$(lsblk -ln -o NAME,TYPE "$DEV" | awk '$2=="part"{print $1}')
  if [ -z "$PARTS" ]; then
    echo "No partition found on $DEV, creating a single partition..."
    parted -s "$DEV" mklabel gpt
    parted -s "$DEV" mkpart primary ext4 0% 100%
    partprobe "$DEV"
    # Wait for partition to appear
    sleep 2
    PARTS=$(lsblk -ln -o NAME,TYPE "$DEV" | awk '$2=="part"{print $1}')
  fi
  PART="/dev/$(echo "$PARTS" | head -n1)"

  if [ ! -b "$PART" ]; then
    echo "Partition $PART not found on $DEV. Skipping $MOUNT_PATH."
    continue
  fi

  # Create filesystem if not present
  FSTYPE=$(blkid -o value -s TYPE "$PART" || true)
  if [ -z "$FSTYPE" ]; then
    echo "Creating ext4 filesystem on $PART"
    mkfs.ext4 -F "$PART"
  fi

  # Create mount point
  mkdir -p "$MOUNT_PATH"

  # Get UUID for fstab
  UUID=$(blkid -s UUID -o value "$PART")
  if ! grep -q "$UUID" /etc/fstab; then
    echo "Adding $PART ($UUID) to /etc/fstab"
    echo "UUID=$UUID $MOUNT_PATH ext4 defaults,nofail 0 2" >> /etc/fstab
  fi

  # Mount the disk
  mount "$MOUNT_PATH"
  echo "$PART mounted at $MOUNT_PATH"
done
