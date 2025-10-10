output "id" {
  description = "Application Load Balancer ID"
  value       = module.alb.id
}

output "name" {
  description = "Application Load Balancer name"
  value       = module.alb.name
}

output "load_balancer_ip" {
  description = "IP address of the created load balancer"
  value       = module.alb.load_balancer_ip
}
