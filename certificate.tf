# Создание приватных ключей для каждого слушателя, у которого включен TLS
resource "tls_private_key" "self_signed" {
  for_each = {
    for k, v in var.listeners : k => v if v["tls"]
  }

  algorithm = "RSA"  # Используем алгоритм RSA для генерации ключей
}

# Создание самоподписанных сертификатов для каждого слушателя, у которого включен TLS и тип сертификата "self_signed"
resource "tls_self_signed_cert" "self_signed" {
  for_each = {
    for k, v in var.listeners : k => v if v["tls"] && v["cert"]["type"] == "self_signed"
  }

  private_key_pem = tls_private_key.self_signed[each.key].private_key_pem  # Используем созданный приватный ключ
  validity_period_hours = 87660  # Сертификат будет действителен 10 лет

  subject {
    common_name = each.value["cert"]["domain"]  # Устанавливаем общее имя домена для сертификата
  }

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]  # Указываем разрешенные использования сертификата
}

# Создание сертификатов в Yandex Certificate Manager для каждого слушателя, у которого включен TLS и тип сертификата "self_signed" или "letsencrypt"
resource "yandex_cm_certificate" "main" {
  for_each = {
    for k, v in var.listeners : k => v if(v["tls"] && (v["cert"]["type"] == "self_signed" || v["cert"]["type"] == "letsencrypt"))
  }

  name        = format("%s-%s", var.name, each.key)  # Формируем имя сертификата
  folder_id   = var.folder_id  # Указываем идентификатор папки в Yandex Cloud
  description = ""  # Описание сертификата (оставлено пустым)
  labels      = var.labels  # Метки для сертификата

  # Если тип сертификата "self_signed", добавляем самоподписанный сертификат
  dynamic "self_managed" {
    for_each = each.value["cert"]["type"] == "self_signed" ? [1] : []
    content {
      certificate = tls_self_signed_cert.self_signed[each.key].cert_pem  # Сертификат
      private_key = tls_self_signed_cert.self_signed[each.key].private_key_pem  # Приватный ключ
    }
  }

  # Если тип сертификата "letsencrypt", указываем домены для сертификата
  domains = each.value["cert"]["type"] == "letsencrypt" ? [
    each.value["cert"]["domain"]
  ] : null

  # Если тип сертификата "letsencrypt", добавляем управляемый сертификат с указанием типа проверки
  dynamic "managed" {
    for_each = each.value["cert"]["type"] == "letsencrypt" ? [1] : []
    content {
      challenge_type = each.value["cert"]["challenge"]  # Тип проверки для сертификата
    }
  }
}
