# Terraform aws account factory

Account Factory Module create OU's upto 3 levels, aws accounts, register the ou with control tower and enroll the accounts. Create OU's and accounts one at a time

## Requirements

* Control Tower Landingzone should be enabled
* Administrative access required at control tower management account as a non-root iam user
* python or python3
* boto3

```bash
$ sudo yum install python3 -y 
$ sudo pip3 install boto3
```

Please refer to example folder for sample code.


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_organizational_unit.ou_level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.ou_level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.ou_level_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [terraform_data.account_enroll](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.ou_register](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.wait_60_seconds_account_enroll](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_60_seconds_ou_register](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ou_map"></a> [ou\_map](#input\_ou\_map) | OU and Account Info | `any` | n/a | yes |
| <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id) | OU id will be considered as root to create ou's and accounts. Default is null, so that the ou's and accounts will be created under Root | `string` | `null` | no |
| <a name="input_python"></a> [python](#input\_python) | python or python3 | `string` | `"python"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_spec"></a> [account\_spec](#output\_account\_spec) | n/a |
| <a name="output_ou_arn"></a> [ou\_arn](#output\_ou\_arn) | n/a |
