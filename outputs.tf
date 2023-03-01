output "id" {
  description = "Application Load Balancer ID"
  value       = yandex_alb_load_balancer.main.id
}

output "name" {
  description = "Application Load Balancer name"
  value       = yandex_alb_load_balancer.main.name
}
