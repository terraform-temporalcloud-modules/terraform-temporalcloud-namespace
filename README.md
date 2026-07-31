# Temporal Cloud Namespace Terraform module

Terraform module which creates a [Temporal Cloud](https://temporal.io/cloud) namespace, along with
its custom search attributes and tags.

## Usage

### API key authentication

```hcl
module "namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "orders-prod"
  regions        = ["aws-us-east-1"]
  retention_days = 30

  api_key_auth = true

  search_attributes = {
    CustomerId = "Keyword"
    OrderTotal = "Double"
  }

  tags = {
    Environment = "prod"
    Team        = "payments"
  }
}
```

### mTLS authentication

```hcl
module "namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "orders-prod"
  regions        = ["aws-us-east-1"]
  retention_days = 30

  # The provider expects the CA bundle Base64-encoded.
  accepted_client_ca = base64encode(file("ca.pem"))

  certificate_filters = [
    {
      common_name  = "worker.example.com"
      organization = "Example Org"
    },
  ]
}
```

### High availability namespace

Passing two regions replicates the namespace across them:

```hcl
module "namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "orders-prod"
  regions        = ["aws-us-east-1", "aws-us-west-2"]
  retention_days = 30
  api_key_auth   = true
}
```

## Notes

A few provider behaviours worth knowing before you plan:

- **Regions cannot be changed after creation.** Adding, removing or changing regions on an existing
  namespace is not supported and the provider raises an error. For HA namespaces the provider ignores
  region *ordering* changes, which occur naturally on failover.
- **`tags` manages the complete tag set.** Tags added outside Terraform are removed on the next apply.
- **`search_attributes` are additive in Temporal Cloud.** A search attribute cannot be deleted once
  created, so removing an entry from the map will fail to destroy. Temporal Cloud also
  [limits](https://docs.temporal.io/cloud/limits#number-of-custom-search-attributes) how many you can
  define.
- **`namespace_lifecycle.enable_delete_protection`** must be set back to `false` and applied before a
  `terraform destroy` will succeed.
- **Authentication.** The provider reads `TEMPORAL_CLOUD_API_KEY` from the environment. Keep it in a
  gitignored `.env`, never in committed `.tfvars`.

## Examples

- [complete](examples/complete) — exercises every input the module supports
- [mtls](examples/mtls) — certificate-based authentication with a generated CA

## Wrapper

To manage many namespaces from a single call, use the [wrapper](wrappers):

```hcl
module "namespaces" {
  source = "terraform-temporalcloud-modules/namespace/temporalcloud//wrappers"

  defaults = {
    regions        = ["aws-us-east-1"]
    retention_days = 30
    api_key_auth   = true
  }

  items = {
    orders   = { name = "orders-prod" }
    payments = { name = "payments-prod", retention_days = 90 }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_temporalcloud"></a> [temporalcloud](#provider\_temporalcloud) | >= 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_namespace.this](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace) | resource |
| [temporalcloud_namespace_search_attribute.this](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace_search_attribute) | resource |
| [temporalcloud_namespace_tags.this](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace_tags) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accepted_client_ca"></a> [accepted\_client\_ca](#input\_accepted\_client\_ca) | The Base64-encoded CA cert in PEM format that clients use when authenticating with Temporal Cloud. Required when the namespace uses mTLS authentication | `string` | `null` | no |
| <a name="input_api_key_auth"></a> [api\_key\_auth](#input\_api\_key\_auth) | If true, Temporal Cloud will enable API key authentication for this namespace | `bool` | `null` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | The capacity configuration for the namespace. `mode` must be one of `provisioned` or `on_demand`; `value` is required when mode is `provisioned` | <pre>object({<br/>    mode  = optional(string)<br/>    value = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_certificate_filters"></a> [certificate\_filters](#input\_certificate\_filters) | A list of filters to apply to client certificates. If present, connections are only allowed from client certificates whose distinguished name properties match at least one filter. Omit rather than passing an empty list | <pre>list(object({<br/>    common_name              = optional(string)<br/>    organization             = optional(string)<br/>    organizational_unit      = optional(string)<br/>    subject_alternative_name = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_codec_server"></a> [codec\_server](#input\_codec\_server) | A codec server used by the Temporal Cloud UI to decode payloads for all users interacting with this namespace, even when the workflow history itself is encrypted | <pre>object({<br/>    endpoint                         = string<br/>    custom_error_link                = optional(string)<br/>    custom_error_message             = optional(string)<br/>    include_cross_origin_credentials = optional(bool)<br/>    pass_access_token                = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_connectivity_rule_ids"></a> [connectivity\_rule\_ids](#input\_connectivity\_rule\_ids) | The IDs of the connectivity rules to attach to this namespace | `set(string)` | `null` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Controls if the namespace should be created | `bool` | `true` | no |
| <a name="input_fairness"></a> [fairness](#input\_fairness) | The fairness configuration for the namespace. Task queue fairness defaults to disabled | <pre>object({<br/>    task_queue_fairness_enabled = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the namespace. Must be 2-64 characters, start with a letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen | `string` | `""` | no |
| <a name="input_namespace_lifecycle"></a> [namespace\_lifecycle](#input\_namespace\_lifecycle) | Temporal Cloud lifecycle configuration, such as delete protection. Unrelated to the Terraform `lifecycle` meta-argument | <pre>object({<br/>    enable_delete_protection = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | The list of regions where this namespace is available. Must be one or two regions, prefixed with the cloud provider (e.g. `aws-us-east-1`, not `us-east-1`). Two regions provisions a high availability (HA) namespace replicated across them | `list(string)` | `[]` | no |
| <a name="input_retention_days"></a> [retention\_days](#input\_retention\_days) | The number of days to retain workflow history. Changes apply to all new running workflows | `number` | `30` | no |
| <a name="input_search_attributes"></a> [search\_attributes](#input\_search\_attributes) | Map of custom search attribute name => type. Valid types: Bool, Datetime, Double, Int, Keyword, KeywordList, Text | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the namespace. The provider manages the complete tag set, so tags applied outside Terraform will be removed | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create and delete timeouts for the namespace, as duration strings (e.g. `30s`, `2h45m`) | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_endpoints"></a> [namespace\_endpoints](#output\_namespace\_endpoints) | All endpoints for the namespace (gRPC, mTLS gRPC and Web UI addresses) |
| <a name="output_namespace_grpc_address"></a> [namespace\_grpc\_address](#output\_namespace\_grpc\_address) | The gRPC address for API key client connections. Empty when API key auth is disabled |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The unique identifier of the namespace across all Temporal Cloud tenants, in the form `<namespace>.<account_id>` |
| <a name="output_namespace_mtls_grpc_address"></a> [namespace\_mtls\_grpc\_address](#output\_namespace\_mtls\_grpc\_address) | The gRPC address for mTLS client connections. Empty when mTLS is disabled |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | The name of the namespace |
| <a name="output_namespace_regions"></a> [namespace\_regions](#output\_namespace\_regions) | The regions the namespace is available in |
| <a name="output_namespace_search_attributes"></a> [namespace\_search\_attributes](#output\_namespace\_search\_attributes) | Map of custom search attribute name => type created on the namespace |
| <a name="output_namespace_tags"></a> [namespace\_tags](#output\_namespace\_tags) | The complete set of tags applied to the namespace |
| <a name="output_namespace_web_address"></a> [namespace\_web\_address](#output\_namespace\_web\_address) | The address of the namespace in the Temporal Cloud Web UI |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](LICENSE).
