module "alb" {
  source = "../"

  name   = "example"
  labels = {}

  region_id = "ru-central1"

  network_id = module.network.vpc_id
  security_group_ids = [
    module.seggroups["default"].id
  ]

  subnets = [
    {
      zone_id         = module.network.private_subnets[0].zone
      id              = module.network.private_subnets[0].id
      disable_traffic = false
    }
  ]

  listeners = {
    http2https = {
      address = "ipv4pub"
      zone_id = "ru-central1-b"
      ports   = ["80"]
      type    = "redirect"
      tls     = false
      cert    = {}
      backend = {}
    }
    http = {
      address = "ipv4prv"
      zone_id = "ru-central1-b"
      ports   = ["8080"]
      type    = "http"
      tls     = false
      cert    = {}
      backend = {}
    }
    http2 = {
      attach_public_ip = false
      zone_id          = "ru-central1-b"
      ports            = ["8081"]
      tls              = false
      type             = "http2"
      cert             = {}
      backend          = {}
    }
    https = {
      address = "ipv4prv"
      zone_id = "ru-central1-b"
      ports   = ["8082"]
      type    = "http"
      tls     = true
      cert = {
        type   = "existing"
        ids    = ["fpqiie14o3cbf8jk2kp6"]
        domain = "my.ru"
      }
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          "MyExampleTargetGroupId"
        ]
        health_check = {
          timeout                 = "30s"
          interval                = "60s"
          interval_jitter_percent = 0
          healthy_threshold       = 1
          unhealthy_threshold     = 1
          healthcheck_port        = 8080
          http = {
            path = "/"
          }
        }
      }
    }

    https2 = {
      address = "ipv4pub"
      zone_id = "ru-central1-a"
      ports   = ["443"]
      type    = "http2"
      tls     = true
      cert = {
        type   = "letsencrypt"
        ids    = []
        domain = "mks.dev.referrs.me"
        # Can be DNS_TXT, DNS_CNAME, HTTP
        challenge = "DNS_TXT"
      }
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          "MyExampleTargetGroupId"
        ]
        health_check = {
          timeout                 = "30s"
          interval                = "60s"
          interval_jitter_percent = 0
          healthy_threshold       = 1
          unhealthy_threshold     = 1
          healthcheck_port        = 8080
          http = {
            path = "/"
          }
        }
      }
    }
  }
}
