data "yandex_client_config" "client" {}

module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = "iam-yandex-compute-instance-group"
  folder_roles = [
    "editor"
  ]
  cloud_roles              = []
  enable_static_access_key = false
  enable_api_key           = false
  enable_account_key       = false
}

module "address" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-address.git?ref=v2.0.0"

  name    = "nlb-pip"
  zone_id = "ru-central1-a"
}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v3.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  blank_name = "vpc-nat-gateway"
  labels = {
    repo = "terraform-yacloud-modules/terraform-yandex-vpc"
  }

  azs = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]

  private_subnets = [["10.3.0.0/24"], ["10.4.0.0/24"], ["10.5.0.0/24"]]

  create_vpc         = true
  create_nat_gateway = true
}

module "seggroups" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-security-group.git?ref=v1.0.0"

  folder_id   = data.yandex_client_config.client.folder_id
  vpc_id      = module.network.vpc_id
  blank_name  = "your-security-group-name"
  description = "Your security group description"
  labels = {
    "key1" = "value1"
    "key2" = "value2"
  }

  ingress_rules = {
    "rule1" = {
      protocol       = "TCP"
      description    = "Allow TCP traffic from 0.0.0.0/0"
      from_port      = 0
      to_port        = 65535
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
    "rule2" = {
      protocol       = "TCP"
      description    = "Allow health check traffic from ALB ranges"
      from_port      = 0
      to_port        = 65535
      v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    }
  }
}

module "instance_group" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance-group.git?ref=v1.0.0"

  zones = ["ru-central1-a"]

  name = "example-alb-instance-group"

  network_id = module.network.vpc_id
  subnet_ids = [module.network.private_subnets_ids[0]]
  enable_nat = true

  scale = {
    fixed = {
      size = 1
    }
  }

  max_checking_health_duration = 10

  health_check = {
    enabled             = true
    interval            = 15
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    tcp_options = {
      port = 22
    }
  }

  platform_id   = "standard-v3"
  cores         = 2
  memory        = 4
  core_fraction = 100

  image_family = "ubuntu-2004-lts"

  enable_alb_integration = true

  hostname           = "example-alb-instance"
  service_account_id = module.iam_accounts.id
  ssh_user           = "ubuntu"
  generate_ssh_key   = false
  ssh_pubkey         = "~/.ssh/id_rsa.pub"

  user_data = <<-EOF
        #cloud-config
        package_upgrade: true
        packages:
          - nginx
        runcmd:
          - [systemctl, start, nginx]
          - [systemctl, enable, nginx]
        EOF

  boot_disk = {
    mode        = "READ_WRITE"
    device_name = "boot"
  }

  boot_disk_initialize_params = {
    size = 30
    type = "network-ssd"
  }

  depends_on = [
    module.iam_accounts,
    module.network,
    module.seggroups,
  ]
}

module "self_managed" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-certificate-manager.git?ref=v2.0.0"

  self_managed = {
    domain-com = {
      description = "self-managed domain certificate from file"
      certificate = file("cert.pem")
      private_key = file("key.pem")
    }
  }
}

module "alb" {
  source = "../.."

  name   = "example"
  labels = {}

  folder_id = data.yandex_client_config.client.folder_id
  region_id = "ru-central1"

  network_id = module.network.vpc_id
  security_group_ids = [
    module.seggroups.id
  ]

  external_ipv4_address = module.address.external_ipv4_address

  subnets = [
    {
      zone_id         = module.network.private_subnets[0].zone
      id              = module.network.private_subnets[0].id
      disable_traffic = false
    }
  ]

  listeners = {
    http = {
      address   = "ipv4prv"
      zone_id   = "ru-central1-a"
      ports     = [8080]
      type      = "http"
      tls       = false
      authority = "domain.com"
      modify_request_headers = [
        {
          name   = "X-Forwarded-For"
          append = "192.168.1.1"
        }
      ]
      modify_response_headers = [
        {
          name   = "X-Cache"
          append = "HIT"
        }
      ]
      cert = {}
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          module.instance_group.target_group_id
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

    http2 = {
      address   = "ipv4prv"
      zone_id   = "ru-central1-a"
      ports     = [8081]
      tls       = false
      type      = "http2"
      cert      = {}
      authority = "domain.com"
      modify_request_headers = [
        {
          name   = "X-Forwarded-For"
          append = "192.168.1.1"
        }
      ]
      modify_response_headers = [
        {
          name   = "X-Cache"
          append = "HIT"
        }
      ]
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          module.instance_group.target_group_id
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
    https = {
      address = "ipv4prv"
      zone_id = "ru-central1-a"
      ports   = [8082]
      type    = "http"
      tls     = true
      cert = {
        type   = "existing"
        ids    = [module.self_managed.self_managed_certificates["domain-com"].id]
        domain = "domain.com"
      }
      authority = "domain.com"
      modify_request_headers = [
        {
          name   = "X-Forwarded-For"
          append = "192.168.1.1"
        }
      ]
      modify_response_headers = [
        {
          name   = "X-Cache"
          append = "HIT"
        }
      ]
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          module.instance_group.target_group_id
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
      ports   = [443]
      type    = "http2"
      tls     = true
      cert = {
        type   = "existing"
        ids    = [module.self_managed.self_managed_certificates["domain-com"].id]
        domain = "domain.com"
      }
      authority = "domain.com"
      modify_request_headers = [
        {
          name   = "X-Forwarded-For"
          append = "192.168.1.1"
        }
      ]
      modify_response_headers = [
        {
          name   = "X-Cache"
          append = "HIT"
        }
      ]
      backend = {
        name   = "app"
        port   = 8080
        weight = 100
        http2  = true
        target_group_ids = [
          module.instance_group.target_group_id
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
