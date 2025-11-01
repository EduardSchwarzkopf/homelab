resource "terraform_data" "additional_disks_trigger" {
  input = jsonencode([
    for d in var.additional_disks : {
      datastore_id      = d.datastore_id
      path_in_datastore = d.path_in_datastore
      size              = tostring(d.size)
    }
  ])
}
