output "domain_com_certificate" {
  description = "Certificate details for domain-com"
  value       = module.self_managed.self_managed_certificates["domain-com"]
}

output "id" {
  value = module.self_managed.self_managed_certificates["domain-com"].id
}

output "instance_group_id" {
  description = "Compute instance group ID"
  value       = module.instance_group.instance_group_id
}

output "target_group_id" {
  description = "Target group ID"
  value       = module.instance_group.target_group_id
}
