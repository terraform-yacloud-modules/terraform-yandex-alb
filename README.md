# Yandex Cloud Application Load Balancer Terraform module

Terraform module which creates Yandex Cloud Application Load Balancer resources.

## Examples

Examples codified under
the [`examples`](https://github.com/terraform-yacloud-modules/terraform-yandex-alb/tree/main/examples) are intended
to give users references for how to use the module(s) as well as testing/validating changes to the source code of the
module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow
maintainers to test your changes and to keep the examples up to date for users. Thank you!

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.1.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.72.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 3.1.0 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.72.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tls_private_key.self_signed](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.self_signed](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [yandex_alb_backend_group.http](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/alb_backend_group) | resource |
| [yandex_alb_backend_group.streams](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/alb_backend_group) | resource |
| [yandex_alb_http_router.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/alb_http_router) | resource |
| [yandex_alb_load_balancer.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/alb_load_balancer) | resource |
| [yandex_alb_virtual_host.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/alb_virtual_host) | resource |
| [yandex_cm_certificate.main](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/cm_certificate) | resource |
| [yandex_vpc_address.pip](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_address) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_pip"></a> [create\_pip](#input\_create\_pip) | If true, public IP will be created | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | ALB description | `string` | `""` | no |
| <a name="input_discard_rules"></a> [discard\_rules](#input\_discard\_rules) | List of logs discard rules | <pre>object({<br/>    http_codes          = optional(list(string), [])<br/>    http_code_intervals = optional(number)<br/>    grpc_codes          = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_enable_logs"></a> [enable\_logs](#input\_enable\_logs) | Set to true to disable Cloud Logging for the balancer | `bool` | `true` | no |
| <a name="input_external_ipv4_address"></a> [external\_ipv4\_address](#input\_external\_ipv4\_address) | External IPv4 address for the load balancer | `string` | `null` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | Folder ID | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of labels | `map(string)` | `{}` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Application load balancer listeners | `any` | `{}` | no |
| <a name="input_log_group_id"></a> [log\_group\_id](#input\_log\_group\_id) | Cloud Logging group ID to send logs to. Leave empty to use the balancer folder default log group | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | ALB name | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | ID of the network that the ALB is located at | `string` | n/a | yes |
| <a name="input_pip_zone_id"></a> [pip\_zone\_id](#input\_pip\_zone\_id) | Public IP zone | `string` | `"ru-central1-a"` | no |
| <a name="input_region_id"></a> [region\_id](#input\_region\_id) | ID of the availability zone where the ALB resides | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of ID's of security groups attached to the ALB | `list(string)` | `[]` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets | <pre>map(object({<br/>    zone_id         = optional(string, "ru-central1-a")<br/>    id              = optional(string, null)<br/>    disable_traffic = optional(bool, false)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Application Load Balancer ID |
| <a name="output_load_balancer_ip"></a> [load\_balancer\_ip](#output\_load\_balancer\_ip) | IP address of the created load balancer |
| <a name="output_name"></a> [name](#output\_name) | Application Load Balancer name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

Apache-2.0 Licensed.
See [LICENSE](https://github.com/terraform-yacloud-modules/terraform-yandex-alb/blob/main/LICENSE).
