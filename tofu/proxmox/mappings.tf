resource "proxmox_virtual_environment_hardware_mapping_pci" "gtx1060" {
  name = "gpu-gtx1060"
  map = [
    {
      id           = "10de:1c03"
      iommu_group  = 9
      node         = local.homeserver_hostname
      path         = "0000:08:00"
      subsystem_id = "1458:371a"
    },
  ]
  mediated_devices = false
}
