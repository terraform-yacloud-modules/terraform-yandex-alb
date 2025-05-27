output "instance_group_id" {
  description = "Compute instance group ID"
  value       = module.instance_group.instance_group_id
}

output "target_group_id" {
  description = "Target group ID"
  value       = module.instance_group.target_group_id
}

output "alb_id" {
  description = "Application Load Balancer ID"
  value       = module.alb.id
}

output "alb_name" {
  description = "Application Load Balancer name"
  value       = module.alb.name
}
