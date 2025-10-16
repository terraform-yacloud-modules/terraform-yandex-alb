resource "yandex_alb_load_balancer" "main" {
  name        = var.name
  description = var.description
  folder_id   = var.folder_id
  labels      = var.labels

  region_id = var.region_id

  network_id         = var.network_id
  security_group_ids = var.security_group_ids

  allocation_policy {
    dynamic "location" {
      for_each = var.subnets

      content {
        zone_id         = location.value["zone_id"]
        subnet_id       = location.value["id"]
        disable_traffic = location.value["disable_traffic"]
      }
    }
  }

  log_options {
    disable      = !var.enable_logs
    log_group_id = var.log_group_id

    dynamic "discard_rule" {
      for_each = var.discard_rules != null ? [1] : []
      content {
        http_codes          = var.discard_rules["http_codes"]
        http_code_intervals = var.discard_rules["http_code_intervals"]
        grpc_codes          = var.discard_rules["grpc_codes"]
      }
    }
  }

  dynamic "listener" {
    for_each = var.listeners
    iterator = l

    content {
      name = l.key

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
              address = var.external_ipv4_address != "" ? var.external_ipv4_address : yandex_vpc_address.pip[0].external_ipv4_address[0].address
            }
          }

          dynamic "external_ipv6_address" {
            for_each = l.value["address"] == "ipv6" ? [1] : []
            content {}
          }
        }

        ports = l.value["ports"]
      }

      # HTTP -> HTTPS
      dynamic "http" {
        for_each = l.value["type"] == "redirect" && !l.value["tls"] ? [1] : []
        content {
          redirects {
            http_to_https = true
          }
        }
      }

      # Plain HTTP
      dynamic "http" {
        for_each = l.value["type"] == "http" && !l.value["tls"] ? [1] : []
        content {
          handler {
            allow_http10   = true
            http_router_id = yandex_alb_http_router.main[l.key].id
          }
        }
      }

      # Plain HTTP2
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

      # Plain stream
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

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

resource "yandex_alb_virtual_host" "main" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name           = format("%s-%s", var.name, each.key)
  http_router_id = yandex_alb_http_router.main[each.key].id
  authority      = [each.value["authority"]]

  dynamic "modify_request_headers" {
    for_each = try(each.value["modify_request_headers"], [])
    content {
      name    = modify_request_headers.value["name"]
      append  = lookup(modify_request_headers.value, "append", null)
      replace = lookup(modify_request_headers.value, "replace", null)
      remove  = lookup(modify_request_headers.value, "remove", null)
    }
  }

  dynamic "modify_response_headers" {
    for_each = try(each.value["modify_response_headers"], [])
    content {
      name    = modify_response_headers.value["name"]
      append  = lookup(modify_response_headers.value, "append", null)
      replace = lookup(modify_response_headers.value, "replace", null)
      remove  = lookup(modify_response_headers.value, "remove", null)
    }
  }

  route {
    name = "default"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.http[each.key].id
        timeout          = "3s"
      }
    }

    # TODO: temporary unsupported
    # grpc_route
  }


  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

resource "yandex_alb_http_router" "main" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name        = format("%s-%s", var.name, each.key)
  description = var.description
  folder_id   = var.folder_id
  labels      = var.labels

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

resource "yandex_alb_backend_group" "http" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "http" || v["type"] == "http2"
  }

  name        = format("%s-%s", var.name, each.key)
  description = var.description
  folder_id   = var.folder_id
  labels      = var.labels

  http_backend {
    name             = each.value["backend"]["name"]
    port             = each.value["backend"]["port"]
    weight           = each.value["backend"]["weight"]
    http2            = each.value["backend"]["http2"]
    target_group_ids = each.value["backend"]["target_group_ids"]

    # TODO: temporary hardcoded
    load_balancing_config {
      locality_aware_routing_percent = 0
      mode                           = "ROUND_ROBIN"
      panic_threshold                = 0
      strict_locality                = false
    }

    healthcheck {
      timeout                 = each.value["backend"]["health_check"]["timeout"]
      interval                = each.value["backend"]["health_check"]["interval"]
      interval_jitter_percent = lookup(each.value["backend"]["health_check"], "interval_jitter_percent", null)
      healthy_threshold       = lookup(each.value["backend"]["health_check"], "healthy_threshold", null)
      unhealthy_threshold     = lookup(each.value["backend"]["health_check"], "unhealthy_threshold", null)
      healthcheck_port        = lookup(each.value["backend"]["health_check"], "healthcheck_port", null)

      http_healthcheck {
        # host = ""
        path  = each.value["backend"]["health_check"]["http"]["path"]
        http2 = each.value["type"] == "http2" ? true : false
      }
    }

    # TODO: temporary unsupported
    # tls {}
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

resource "yandex_alb_backend_group" "streams" {
  for_each = {
    for k, v in var.listeners : k => v if v["type"] == "stream"
  }

  name        = each.key
  description = var.description
  folder_id   = var.folder_id
  labels      = var.labels

  stream_backend {
    name             = each.value["backend"]["name"]
    port             = each.value["backend"]["port"]
    weight           = each.value["backend"]["weight"]
    target_group_ids = each.value["backend"]["target_group_ids"]

    # TODO: temporary unsupported
    # load_balancing_config {}

    healthcheck {
      timeout                 = each.value["backend"]["health_check"]["timeout"]
      interval                = each.value["backend"]["health_check"]["interval"]
      interval_jitter_percent = lookup(each.value["backend"]["health_check"], "interval_jitter_percent", null)
      healthy_threshold       = lookup(each.value["backend"]["health_check"], "healthy_threshold", null)
      unhealthy_threshold     = lookup(each.value["backend"]["health_check"], "unhealthy_threshold", null)
      healthcheck_port        = lookup(each.value["backend"]["health_check"], "healthcheck_port", null)

      # TODO: temporary unsupported
      #      stream_healthcheck {
      #        send    = "/"
      #        receive = ""
      #      }
    }

    # TODO: temporary unsupported
    # tls {}
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

# TODO: temporary unsupported
# resource "yandex_alb_backend_group" "grpc" {}
