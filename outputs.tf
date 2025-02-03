output "id" {
  description = "Application Load Balancer ID"
  value       = yandex_alb_load_balancer.main.id
}

output "name" {
  description = "Application Load Balancer name"
  value       = yandex_alb_load_balancer.main.name
}

output "load_balancer_ip" {
  description = "IP address of the created load balancer"
  value       = var.external_ipv4_address != "" ? var.external_ipv4_address : yandex_vpc_address.pip[0].external_ipv4_address[0].address
}
