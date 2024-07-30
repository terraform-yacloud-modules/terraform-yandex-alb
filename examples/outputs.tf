output "domain_com_certificate" {
  description = "Certificate details for domain-com"
  value       = module.self_managed.self_managed_certificates["domain-com"]
}

output "id" {
  value = module.self_managed.self_managed_certificates["domain-com"].id
}
