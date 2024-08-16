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

module "address" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-address.git"

  name    = "nlb-pip"
  zone_id = "ru-central1-a"
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

module "dns_zone" {

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-dns.git//modules/zone?ref=v1.0.0"

  name        = "my-private-zone"
  description = "desc"

  zone             = "apatsev.org.ru."
  is_public        = true
  private_networks = [module.network.vpc_id]
}

module "dns_recordset" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-dns.git//modules/recordset?ref=v1.0.0"

  zone_id = module.dns_zone.id
  name    = "test.apatsev.org.ru."
  type    = "A"
  ttl     = 200
  data    = [module.address.external_ipv4_address]
}


module "alb" {
  source = "../"

  name   = "example"
  labels = {}

  region_id = "ru-central1"

  network_id = module.network.vpc_id

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
      address   = "ipv4pub"
      zone_id   = "ru-central1-b"
      ports     = [80]
      type      = "http"
      tls       = false
      authority = "test.apatsev.org.ru"
      backend = {
        name   = "app"
        port   = 80
        weight = 100
        http2  = false
        target_group_ids = [
          module.instance_group.target_group_id
        ]
        health_check = {
          timeout                 = "30s"
          interval                = "60s"
          interval_jitter_percent = 0
          healthy_threshold       = 1
          unhealthy_threshold     = 1
          healthcheck_port        = 80
          http = {
            path = "/"
          }
        }
      }
    }

  }
}
