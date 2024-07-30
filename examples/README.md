# Example ALB

## Usage

To run this example you need to execute:

```bash
export YC_FOLDER_ID='folder_id'
terraform init
terraform plan
terraform apply
```

Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.72.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.72.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ../ | n/a |
| <a name="module_iam_accounts"></a> [iam\_accounts](#module\_iam\_accounts) | git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account | v1.0.0 |
| <a name="module_instance_group"></a> [instance\_group](#module\_instance\_group) | git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance-group.git | n/a |
| <a name="module_network"></a> [network](#module\_network) | git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git | v1.0.0 |
| <a name="module_seggroups"></a> [seggroups](#module\_seggroups) | git::https://github.com/terraform-yacloud-modules/terraform-yandex-security-group.git | v1.0.0 |
| <a name="module_self_managed"></a> [self\_managed](#module\_self\_managed) | git::https://github.com/terraform-yacloud-modules/terraform-yandex-certificate-manager.git | n/a |

## Resources

| Name | Type |
|------|------|
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_com_certificate"></a> [domain\_com\_certificate](#output\_domain\_com\_certificate) | Certificate details for domain-com |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_instance_group_id"></a> [instance\_group\_id](#output\_instance\_group\_id) | Compute instance group ID |
| <a name="output_target_group_id"></a> [target\_group\_id](#output\_target\_group\_id) | Target group ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

Apache-2.0 Licensed.
See [LICENSE](https://github.com/terraform-yacloud-modules/terraform-yandex-alb/blob/main/LICENSE).
