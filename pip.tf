resource "yandex_vpc_address" "pip" {
  for_each = {
    for k, v in var.listeners : k => v if v["address"] == "ipv4pub"
  }

  name        = format("%s-alb-%s", var.name, each.key)
  description = var.description
  folder_id   = var.folder_id
  labels      = var.labels
}
