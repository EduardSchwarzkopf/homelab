# Backup Tier Quick Reference

## Tier Comparison Table

| Aspect                | Tier 1 (Critical)                  | Tier 2 (Standard)     | Tier 3 (Dev)  | Tier 4 (Cache)           |
| --------------------- | ---------------------------------- | --------------------- | ------------- | ------------------------ |
| **Numeric ID**        | `1`                                | `2`                   | `3`           | `4`                      |
| **Pool Name**         | `tier-1`                           | `tier-2`              | `tier-3`      | `tier-4`                 |
| **Backup Frequency**  | Daily                              | Weekly                | Monthly       | Quarterly                |
| **Backup Time (UTC)** | 21:00                              | 21:00                 | 21:00         | 21:00                    |
| **Retention Period**  | 30 days                            | 84 days               | 90 days       | 180 days                 |
| **RPO**               | 24 hours                           | 7 days                | 30 days       | 90 days                  |
| **RTO**               | 4 hours                            | 24 hours              | 48 hours      | 1 week                   |
| **Verification**      | Enabled                            | Enabled               | Enabled       | Disabled                 |
| **Recovery Testing**  | Monthly                            | Quarterly             | Annually      | Not required             |
| **Use Cases**         | Production data, critical services | App config, user data | Dev/test data | Caches, regenerable data |
| **Examples**          | Postgres, PBS                      | App state             | Sandbox       | Ollama models            |

## Quick Decision Tree

```
Is the data critical to operations?
├─ YES → Is it production data?
│  ├─ YES → Tier 1 (Critical)
│  └─ NO → Tier 2 (Standard)
└─ NO → Is it development/testing?
   ├─ YES → Tier 3 (Dev)
   └─ NO → Tier 4 (Cache)
```

## Module Usage Cheat Sheet

### Tier 1 - Critical
```hcl
module "critical_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "postgres"
  node_name        = "proxmox-node-1"
  size             = 50
  backup_tier      = 1
}
```

### Tier 2 - Standard
```hcl
module "standard_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "myapp"
  node_name        = "proxmox-node-1"
  size             = 100
  backup_tier      = 2
}
```

### Tier 3 - Dev
```hcl
module "dev_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "sandbox"
  node_name        = "proxmox-node-1"
  size             = 50
  backup_tier      = 3
}
```

### Tier 4 - Cache
```hcl
module "cache_data" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "ollama"
  node_name        = "proxmox-node-1"
  size             = 150
  backup_tier      = 4
}
```

## Backup Schedule

```
21:00 UTC ─ Tier 1 (Critical) - Daily
21:00 UTC ─ Tier 2 (Standard) - Weekly (Sunday)
21:00 UTC ─ Tier 3 (Dev) - Monthly (1st)
21:00 UTC ─ Tier 4 (Cache) - Quarterly (1st of Q)
```

## Backup Flow

```
Application Data
    ↓
Persistent Volume (Longhorn)
    ↓
Longhorn Snapshot
    ↓
Backup Pool (tier-1, tier-2, etc.)
    ↓
ZFS Replication
    ↓
Proxmox Backup Server
    ↓
Backup Storage (on-site)
```

This flow ensures data is captured at multiple layers:
1. **Application Level**: Data written to persistent volumes
2. **Storage Level**: Longhorn snapshots provide point-in-time recovery
3. **Backup Level**: Tiered pools organize backups by criticality
4. **Replication Level**: ZFS replication provides redundancy
5. **Archive Level**: Proxmox Backup Server stores backups long-term

## Common Tasks

### Add a New Data Disk with Tier 1
```bash
# Edit VM's data_vm.tf
module "data_vm" {
  source           = "../modules/data_disk_vm"
  consumer_vm_name = "myvm"
  node_name        = "proxmox-node-1"
  size             = 100
  backup_tier      = 1
}

# Apply
cd tofu/infrastructure
tofu apply
```

### Change Tier of Existing Data Disk
```bash
# Edit VM's data_vm.tf - change backup_tier value
backup_tier = 2  # Changed from 1

# Apply
tofu apply
```

### View Data Disk Tier
```bash
# In Proxmox UI:
# 1. Go to Datacenter → Pools
# 2. Select the tier pool (e.g., tier-1)
# 3. View data disk VMs in that pool

# Or via CLI:
pvesh get /pools/tier-1
```

## Tier Selection Criteria

### Choose Tier 1 if ANY of these apply:
- ✓ Production database
- ✓ critical data
- ✓ Data loss would make me very sad 
- ✓ Recovery needed within hours

### Choose Tier 2 if ANY of these apply:
- ✓ Application configuration
- ✓ User data
- ✓ Standard data
- ✓ Recovery needed within 24 hours
- ✓ Data loss would cause minor impact

### Choose Tier 3 if ANY of these apply:
- ✓ Development environment
- ✓ Testing data
- ✓ Staging environment
- ✓ Recovery needed within 48 hours
- ✓ Data can be partially regenerated

### Choose Tier 4 if ANY of these apply:
- ✓ Cache data
- ✓ Temporary files
- ✓ Regenerable data
- ✓ Recovery needed within a week
- ✓ Data loss has minimal impact

