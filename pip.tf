# Создание ресурса статического публичного IP-адреса в Yandex Cloud, если var.create_pip установлено в true
resource "yandex_vpc_address" "pip" {
  count = var.create_pip ? 1 : 0  # Создается один ресурс, если var.create_pip истинно, иначе не создается

  name        = format("%s-alb", var.name)  # Имя ресурса, сформированное из переменной var.name с добавлением "-alb"
  description = ""  # Описание ресурса (оставлено пустым)
  folder_id   = var.folder_id  # Идентификатор папки в Yandex Cloud, где будет создан ресурс
  labels      = var.labels  # Метки для ресурса, переданные через переменную var.labels

  # Конфигурация внешнего IPv4-адреса
  external_ipv4_address {
    zone_id = var.pip_zone_id  # Идентификатор зоны, в которой будет создан внешний IPv4-адрес
  }
}
