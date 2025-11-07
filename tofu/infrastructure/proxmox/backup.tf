resource "proxmox_virtual_environment_pool" "tier_0_none" {
  comment = "Tier 0: No Backup"
  pool_id = "tier-0"
}

resource "proxmox_virtual_environment_pool" "tier_1_critical" {
  comment = "Tier 1: Critical Production Data - Daily backups, 30-day retention"
  pool_id = "tier-1"
}

resource "proxmox_virtual_environment_pool" "tier_2_standard" {
  comment = "Tier 2: Standard Application Data - Weekly backups, 84-day retention"
  pool_id = "tier-2"
}

resource "proxmox_virtual_environment_pool" "tier_3_dev" {
  comment = "Tier 3: Development/Testing Data - Monthly backups, 90-day retention"
  pool_id = "tier-3"
}

resource "proxmox_virtual_environment_pool" "tier_4_cache" {
  comment = "Tier 4: Cache/Temporary Data - Quarterly backups, 180-day retention"
  pool_id = "tier-4"
}
