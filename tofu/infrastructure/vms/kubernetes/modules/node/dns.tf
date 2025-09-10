
resource "time_sleep" "wait_for_dhcp" {
  depends_on = [proxmox_virtual_environment_vm.vm]

  create_duration = "60s"
}

data "dns_a_record_set" "this" {
  depends_on = [time_sleep.wait_for_dhcp, proxmox_virtual_environment_vm.vm]
  for_each   = { for vm in proxmox_virtual_environment_vm.vm : vm.name => vm }
  host       = each.key
}
