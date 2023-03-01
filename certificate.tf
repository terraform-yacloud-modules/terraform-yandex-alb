resource "tls_private_key" "self_signed" {
  for_each = {
    for k, v in var.listeners : k => v if v["tls"]
  }

  algorithm = "RSA"
}

resource "tls_self_signed_cert" "self_signed" {
  for_each = {
    for k, v in var.listeners : k => v if v["tls"] && v["cert"]["type"] == "self_signed"
  }

  private_key_pem = tls_private_key.self_signed[each.key].private_key_pem
  # 10 years
  validity_period_hours = 87660

  subject {
    common_name = each.value["cert"]["domain"]
  }

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "yandex_cm_certificate" "main" {
  for_each = {
    for k, v in var.listeners : k => v if(v["tls"] && (v["cert"]["type"] == "self_signed" || v["cert"]["type"] == "letsencrypt"))
  }

  name        = format("%s-%s", var.name, each.key)
  folder_id   = var.folder_id
  description = ""
  labels      = var.labels

  dynamic "self_managed" {
    for_each = each.value["cert"]["type"] == "self_signed" ? [1] : []
    content {
      certificate = tls_self_signed_cert.self_signed[each.key].cert_pem
      private_key = tls_self_signed_cert.self_signed[each.key].private_key_pem
    }
  }

  domains = each.value["cert"]["type"] == "letsencrypt" ? [
    each.value["cert"]["domain"]
  ] : null

  dynamic "managed" {
    for_each = each.value["cert"]["type"] == "letsencrypt" ? [1] : []
    content {
      challenge_type = each.value["cert"]["challenge"]
    }
  }
}
