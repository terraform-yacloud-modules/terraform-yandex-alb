module "wrapper" {
  source = "../"

  for_each = var.items

  create_pip                  = try(each.value.create_pip, var.defaults.create_pip, true)
  description                 = try(each.value.description, var.defaults.description, null)
  discard_rules               = try(each.value.discard_rules, var.defaults.discard_rules, null)
  enable_logs                 = try(each.value.enable_logs, var.defaults.enable_logs, true)
  external_ipv4_address       = try(each.value.external_ipv4_address, var.defaults.external_ipv4_address, null)
  folder_id                   = try(each.value.folder_id, var.defaults.folder_id, null)
  labels                      = try(each.value.labels, var.defaults.labels, {})
  listeners                   = try(each.value.listeners, var.defaults.listeners, {})
  log_group_id                = try(each.value.log_group_id, var.defaults.log_group_id, "")
  name                        = try(each.value.name, var.defaults.name, null)
  network_id                  = try(each.value.network_id, var.defaults.network_id, null)
  pip_zone_id                 = try(each.value.pip_zone_id, var.defaults.pip_zone_id, "ru-central1-a")
  region_id                   = try(each.value.region_id, var.defaults.region_id, null)
  security_group_ids          = try(each.value.security_group_ids, var.defaults.security_group_ids, [])
  subnets                     = try(each.value.subnets, var.defaults.subnets, {})
}
