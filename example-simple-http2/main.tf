data "yandex_client_config" "client" {}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  blank_name = "alb-vpc-nat-gateway"
  labels = {
    repo = "terraform-yacloud-modules/terraform-yandex-vpc"
  }

  azs = ["ru-central1-a"]

  private_subnets = [["10.2.0.0/24"]]

  create_vpc         = true
  create_nat_gateway = true
}

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

module "instance_group" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance-group.git"

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

  depends_on = [module.iam_accounts]
}

module "self_managed" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-certificate-manager.git"

  self_managed = {
    domain-com = {
      description = "self-managed domain certificate from file"
      certificate = file("cert.pem")
      private_key = file("key.pem")
    }
  }
}

module "alb" {
  source = "../"

  name   = "my-alb-http2"
  labels = {}

  folder_id = data.yandex_client_config.client.folder_id
  region_id = "ru-central1"

  network_id = module.network.vpc_id

  subnets = [
    {
      zone_id         = module.network.private_subnets[0].zone
      id              = module.network.private_subnets[0].id
      disable_traffic = false
    }
  ]

  create_pip   = true
  pip_zone_id  = "ru-central1-a"

  listeners = {
    web = {
      type      = "http2"
      address   = "ipv4pub"
      ports     = [443]
      tls       = true
      authority = "domain.com"

      cert = {
        type   = "existing"
        ids    = [module.self_managed.self_managed_certificates["domain-com"].id]
        domain = "domain.com"
      }

      backend = {
        name   = "app"
        port   = 80
        weight = 100
        http2  = true
        target_group_ids = [
          module.instance_group.target_group_id
        ]

        health_check = {
          timeout             = "30s"
          interval            = "60s"
          healthy_threshold   = 1
          unhealthy_threshold = 1

          http = {
            path = "/"
          }
        }
      }

      modify_request_headers = [
        {
          name    = "X-Forwarded-Proto"
          replace = "https"
        }
      ]

      modify_response_headers = [
        {
          name   = "X-Frame-Options"
          append = "DENY"
        }
      ]
    }

    redirect = {
      type    = "redirect"
      address = "ipv4pub"
      ports   = [80]
      tls     = false
    }
  }
}
