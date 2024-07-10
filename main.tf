# Создание Yandex Application Load Balancer (ALB) с указанными параметрами
resource "yandex_alb_load_balancer" "main" {
  name        = var.name  # Имя балансировщика
  description = var.description  # Описание балансировщика
  folder_id   = var.folder_id  # Идентификатор папки в Yandex Cloud
  labels      = var.labels  # Метки для балансировщика

  region_id = var.region_id  # Идентификатор региона

  network_id         = var.network_id  # Идентификатор сети
  security_group_ids = var.security_group_ids  # Список идентификаторов групп безопасности

  # Настройка политики распределения
  allocation_policy {
    dynamic "location" {
      for_each = var.subnets  # Для каждой подсети

      content {
        zone_id         = location.value["zone_id"]  # Идентификатор зоны
        subnet_id       = location.value["id"]  # Идентификатор подсети
        disable_traffic = location.value["disable_traffic"]  # Флаг отключения трафика
      }
    }
  }

  # Настройка опций логирования
  log_options {
    disable      = !var.enable_logs  # Флаг отключения логирования
    log_group_id = var.log_group_id  # Идентификатор группы логирования

    # Динамическая настройка правил игнорирования логов
    dynamic "discard_rule" {
      for_each = var.discard_rules != null ? [1] : []
      content {
        http_codes          = var.discard_rules["http_codes"]
        http_code_intervals = var.discard_rules["http_code_intervals"]
        grpc_codes          = var.discard_rules["grpc_codes"]
      }
    }
  }

  # Динамическая настройка слушателей
  dynamic "listener" {
    for_each = var.listeners
    iterator = l

    content {
      name = l.key  # Имя слушателя

      endpoint {
        address {
          dynamic "internal_ipv4_address" {
            for_each = l.value["address"] == "ipv4prv" ? [1] : []
            content {
              subnet_id = lookup(l.value, "zone", null) != null ? l.value["zone"] : var.subnets[0].id
            }
          }

          dynamic "external_ipv4_address" {
            for_each = l.value["address"] == "ipv4pub" ? [1] : []
            content {
              address = yandex_vpc_address.pip[0].external_ipv4_address[0].address
            }
          }

          dynamic "external_ipv6_address" {
            for_each = l.value["address"] == "ipv6" ? [1] : []
            content {}
          }
        }

        ports = l.value["ports"]  # Порты слушателя
      }

      # Перенаправление HTTP -> HTTPS
      dynamic "http" {
        for_each = l.value["type"] == "redirect" && !l.value["tls"] ? [1] : []
        content {
          redirects {
            http_to_https = true
          }
        }
      }

      # Простой HTTP
      dynamic "http" {
        for_each = l.value["type"] == "http" && !l.value["tls"] ? [1] : []
        content {
          handler {
            allow_http10   = true
            http_router_id = yandex_alb_http_router.main[l.key].id
          }
        }
      }

      # Простой HTTP2
      dynamic "http" {
        for_each = l.value["type"] == "http2" && !l.value["tls"] ? [1] : []
        content {
          handler {
            http2_options {
              max_concurrent_streams = 100
            }
            allow_http10   = false
            http_router_id = yandex_alb_http_router.main[l.key].id
          }
        }
      }

      # Простой stream
      dynamic "stream" {
        for_each = l.value["type"] == "stream" && !l.value["tls"] ? [1] : []
        content {
          handler {
            backend_group_id = "TODO"
          }
        }
      }

      # TLS HTTP
      dynamic "tls" {
        for_each = l.value["type"] == "http" && l.value["tls"] ? [1] : []
        content {
          default_handler {
            http_handler {
              http_router_id = yandex_alb_http_router.main[l.key].id
              allow_http10   = true
            }
            certificate_ids = l.value["cert"]["type"] == "existing" ? l.value["cert"]["ids"] : [
              yandex_cm_certificate.main[l.key].id
            ]
          }
        }
      }

      # TLS HTTP2
      dynamic "tls" {
        for_each = l.value["type"] == "http2" && l.value["tls"] ? [1] : []
        content {
          default_handler {
            http_handler {
              http2_options {
                max_concurrent_streams = 100
              }
              allow_http10   = false
              http_router_id = yandex_alb_http_router.main[l.key].id
            }
            certificate_ids = l.value["cert"]["type"] == "existing" ? l.value["cert"]["ids"] : [
              yandex_cm_certificate.main[l.key].id
            ]
          }
        }
      }

      # TLS Stream
      dynamic "tls" {
        for_each = l.value["type"] == "stream" && l.value["tls"] ? [1] : []
        content {
          stream_handler {
            backend_group_id = "TODO"
          }
          certificate_ids = [yandex_cm_certificate.main[l.key].id]
        }
      }
    }
  }
}

# Создание виртуального хоста для каждого слушателя типа HTTP или HTTP2
resource "yandex_alb_virtual_host" "main" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name           = format("%s-%s", var.name, each.key)  # Имя виртуального хоста
  http_router_id = yandex_alb_http_router.main[each.key].id  # Идентификатор HTTP роутера

  # TODO: temporary unsupported args
  # authority
  # modify_request_headers
  # modify_response_headers

  route {
    name = "default"  # Имя маршрута по умолчанию
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.http[each.key].id  # Идентификатор группы бэкендов
        timeout          = "3s"  # Таймаут маршрута
      }
    }

    # TODO: temporary unsupported
    # grpc_route
  }
}

# Создание HTTP роутера для каждого слушателя типа HTTP или HTTP2
resource "yandex_alb_http_router" "main" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name        = format("%s-%s", var.name, each.key)  # Имя HTTP роутера
  description = var.description  # Описание HTTP роутера
  folder_id   = var.folder_id  # Идентификатор папки в Yandex Cloud
  labels      = var.labels  # Метки для HTTP роутера
}

# Создание группы бэкендов для каждого слушателя типа HTTP или HTTP2
resource "yandex_alb_backend_group" "http" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name        = format("%s-%s", var.name, each.key)  # Имя группы бэкендов
  description = var.description  # Описание группы бэкендов
  folder_id   = var.folder_id  # Идентификатор папки в Yandex Cloud
  labels      = var.labels  # Метки для группы бэкендов

  http_backend {
    name             = each.value["backend"]["name"]  # Имя бэкенда
    port             = each.value["backend"]["port"]  # Порт бэкенда
    weight           = each.value["backend"]["weight"]  # Вес бэкенда
    http2            = each.value["backend"]["http2"]  # Флаг использования HTTP2
    target_group_ids = each.value["backend"]["target_group_ids"]  # Идентификаторы целевых групп

    # TODO: temporary hardcoded
    load_balancing_config {
      locality_aware_routing_percent = 0
      mode                           = "ROUND_ROBIN"
      panic_threshold                = 0
      strict_locality                = false
    }

    healthcheck {
      timeout                 = each.value["backend"]["health_check"]["timeout"]  # Таймаут проверки
      interval                = each.value["backend"]["health_check"]["interval"]  # Интервал проверки
      interval_jitter_percent = lookup(each.value["backend"]["health_check"], "interval_jitter_percent", null)  # Процент джиттера интервала
      healthy_threshold       = lookup(each.value["backend"]["health_check"], "healthy_threshold", null)  # Порог здоровья
      unhealthy_threshold     = lookup(each.value["backend"]["health_check"], "unhealthy_threshold", null)  # Порог нездоровья
      healthcheck_port        = lookup(each.value["backend"]["health_check"], "healthcheck_port", null)  # Порт проверки

      http_healthcheck {
        # host = ""
        path  = each.value["backend"]["health_check"]["http"]["path"]  # Путь проверки
        http2 = each.value["type"] == "http2" ? true : false  # Флаг использования HTTP2
      }
    }

    # TODO: temporary unsupported
    # tls {}
  }
}

# Создание группы бэкендов для каждого слушателя типа stream
resource "yandex_alb_backend_group" "streams" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "stream"
  }

  name        = each.key  # Имя группы бэкендов
  description = var.description  # Описание группы бэкендов
  folder_id   = var.folder_id  # Идентификатор папки в Yandex Cloud
  labels      = var.labels  # Метки для группы бэкендов

  stream_backend {
    name             = each.value["backend"]["name"]  # Имя бэкенда
    port             = each.value["backend"]["port"]  # Порт бэкенда
    weight           = each.value["backend"]["weight"]  # Вес бэкенда
    target_group_ids = each.value["backend"]["target_group_ids"]  # Идентификаторы целевых групп

    # TODO: temporary unsupported
    # load_balancing_config {}

    healthcheck {
      timeout                 = each.value["backend"]["health_check"]["timeout"]  # Таймаут проверки
      interval                = each.value["backend"]["health_check"]["interval"]  # Интервал проверки
      interval_jitter_percent = lookup(each.value["backend"]["health_check"], "interval_jitter_percent", null)  # Процент джиттера интервала
      healthy_threshold       = lookup(each.value["backend"]["health_check"], "healthy_threshold", null)  # Порог здоровья
      unhealthy_threshold     = lookup(each.value["backend"]["health_check"], "unhealthy_threshold", null)  # Порог нездоровья
      healthcheck_port        = lookup(each.value["backend"]["health_check"], "healthcheck_port", null)  # Порт проверки

      # TODO: temporary unsupported
      #      stream_healthcheck {
      #        send    = "/"
      #        receive = ""
      #      }
    }

    # TODO: temporary unsupported
    # tls {}
  }
}

# TODO: temporary unsupported
# resource "yandex_alb_backend_group" "grpc" {}
