# Вывод идентификатора Application Load Balancer
output "id" {
  description = "Application Load Balancer ID"  # Описание вывода
  value       = yandex_alb_load_balancer.main.id  # Значение вывода - идентификатор ALB
}

# Вывод имени Application Load Balancer
output "name" {
  description = "Application Load Balancer name"  # Описание вывода
  value       = yandex_alb_load_balancer.main.name  # Значение вывода - имя ALB
}
