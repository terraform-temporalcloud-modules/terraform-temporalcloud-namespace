# Temporal Cloud Namespace Terraform module

[![CI](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/actions/workflows/pre-commit.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/actions/workflows/pre-commit.yml?query=branch%3Amain)
[![Apply Tests](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/actions/workflows/test.yml?query=branch%3Amain)

Terraform module which creates a [Temporal Cloud](https://temporal.io/cloud) namespace, together with
its custom search attributes and tags.

## Requirements

The `temporalcloud` provider authenticates with an API key, read from the `TEMPORAL_CLOUD_API_KEY`
environment variable:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"
```

The provider authenticates when it initialises, so a key is needed even for a `terraform plan` that
would create nothing. Keep the key out of version control — an untracked `.env` file rather than a
committed `.tfvars`.

A namespace also needs at least one client authentication method: `api_key_auth`, an
`accepted_client_ca` for mTLS, or both.

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
    CustomerId = "keyword"
    OrderTotal = "double"
  }

  tags = {
    environment = "prod"
    team        = "payments"
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

Passing two regions replicates the namespace across both. Not every pair is
permitted — Temporal Cloud restricts which regions may be combined, and an
unsupported pair is rejected at apply with `Selected regions <a> and <b> are
disallowed`. Same-provider pairs are not automatically valid; check with Temporal
which combinations your account supports:

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

## Choosing regions

Region IDs are prefixed with the cloud provider — `aws-us-east-1`, not `us-east-1`. The
[published region list](https://docs.temporal.io/cloud/regions) shows what Temporal Cloud offers
overall, but **the regions your account may use are a subset of it**. Using one your account is not
entitled to fails at apply with:

```text
Error: Invalid Region
Region "aws-us-east-1" is not a valid Temporal Cloud region.
```

To list the regions available to your account:

```hcl
data "temporalcloud_regions" "available" {}

output "available_regions" {
  value = [for r in data.temporalcloud_regions.available.regions : r.id]
}
```

## Notes

Provider and Temporal Cloud behaviours worth knowing before you plan:

- **Regions cannot be changed after creation.** Adding, removing or changing regions on an existing
  namespace is rejected. For high availability namespaces, region *ordering* changes are ignored, since
  those occur naturally on failover.
- **Search attributes cannot be deleted.** Temporal Cloud has no delete operation for them, so removing
  an entry from `search_attributes` drops it from Terraform state while leaving it on the namespace.
  There are also [limits](https://docs.temporal.io/cloud/limits#number-of-custom-search-attributes) on
  how many a namespace may have.
- **Search attribute types use underscores**: `keyword_list`, not `KeywordList`. Types are matched
  case-insensitively, so `Keyword` is accepted but `KeywordList` is not.
- **Tag keys must be lowercase**, and `tags` replaces the namespace's entire tag set. Tags added
  outside Terraform are removed on the next apply.
- **Delete protection blocks destroy.** With `namespace_lifecycle.enable_delete_protection = true`, set
  it back to `false` and apply before `terraform destroy` will succeed.

## Examples

- [complete](examples/complete) — a full configuration covering authentication, capacity, codec server,
  search attributes and tags
- [mtls](examples/mtls) — certificate-based authentication, with a generated CA so it runs unmodified

## Managing several namespaces

The [`wrappers`](wrappers) submodule creates many namespaces from one call, for use with Terragrunt or
anywhere a `for_each` on the module block is awkward:

```hcl
module "namespaces" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud//wrappers"
  version = "~> 1.0"

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

## Which inputs are required

The generated **Inputs** table below marks `name` and `regions` as required, and Terraform enforces
that — including when `create_namespace = false`, where the module creates nothing but still needs a
value. Pass `name = ""` and `regions = []` to switch the module off.

The rules the table cannot express are below.

### Conditionally required

| Input | Required when | Surfaces at |
| ----- | ------------- | ----------- |
| `api_key_auth` or `accepted_client_ca` | Always. A namespace must accept at least one authentication method; setting both is valid. | Apply. The provider raises `Namespace not configured with authentication` / `accepted_client_ca or api_key_auth must be set`. |
| `codec_server.endpoint` | `codec_server` is set | `terraform validate` |
| `capacity.value` | `capacity.mode = "provisioned"` | `terraform validate` |
| `capacity` | It was set by a previous apply. Capacity cannot be removed once set — revert with `capacity = { mode = "on_demand" }` rather than dropping the variable. | Plan |
| `fairness` | It was set by a previous apply. Fairness cannot be removed once set — disable with `fairness = { task_queue_fairness_enabled = false }` rather than dropping the variable. | Plan |

Two neighbouring constraints that are not about required-ness but bite in the same place:

- **`capacity.mode = "provisioned"` is refused while creating a namespace** —
  `only 'on_demand' capacity mode is supported when creating a namespace`. Provisioned capacity can
  only be set on a namespace that already exists.
- **`certificate_filters` needs `accepted_client_ca` to do anything.** The provider attaches them to
  the mTLS configuration, so filters passed without a CA are silently ignored rather than rejected.

A configuration that passes `terraform validate` can still be missing an authentication method —
validate does not check for one. Use `terraform plan`.

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
| <a name="input_accepted_client_ca"></a> [accepted\_client\_ca](#input\_accepted\_client\_ca) | Base64-encoded CA certificate in PEM format that clients present when authenticating, for example `base64encode(file("ca.pem"))`. Required to use mTLS. Set this, `api_key_auth`, or both — a namespace must accept at least one authentication method, and the provider rejects one that accepts neither | `string` | `null` | no |
| <a name="input_api_key_auth"></a> [api\_key\_auth](#input\_api\_key\_auth) | Enables API key authentication for this namespace. Set this, `accepted_client_ca`, or both — a namespace must accept at least one authentication method, and the provider rejects one that accepts neither | `bool` | `null` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Capacity configuration. `mode` is `provisioned` or `on_demand`, and `value` is required when mode is `provisioned`. Only `on_demand` is accepted while creating a namespace, so `provisioned` can be set only on one that already exists. Once capacity is set it cannot be removed — revert with `mode = "on_demand"` rather than dropping the variable | <pre>object({<br/>    mode  = optional(string)<br/>    value = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_certificate_filters"></a> [certificate\_filters](#input\_certificate\_filters) | Filters applied to client certificates. When set, connections are accepted only from certificates whose distinguished name matches at least one filter. Takes effect only alongside `accepted_client_ca` — filters supplied without a CA are ignored. Omit rather than passing an empty list | <pre>list(object({<br/>    common_name              = optional(string)<br/>    organization             = optional(string)<br/>    organizational_unit      = optional(string)<br/>    subject_alternative_name = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_codec_server"></a> [codec\_server](#input\_codec\_server) | Codec server the Temporal Cloud UI uses to decode payloads for everyone viewing this namespace, including when the workflow history itself is encrypted. `endpoint` is required whenever this is set, and must begin with `https`. No codec server is configured when omitted | <pre>object({<br/>    endpoint                         = string<br/>    custom_error_link                = optional(string)<br/>    custom_error_message             = optional(string)<br/>    include_cross_origin_credentials = optional(bool)<br/>    pass_access_token                = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_connectivity_rule_ids"></a> [connectivity\_rule\_ids](#input\_connectivity\_rule\_ids) | IDs of connectivity rules to attach to this namespace. No rules are attached when omitted. Omit rather than passing an empty set, which the provider rejects | `set(string)` | `null` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Controls if the namespace should be created. Set to `false` to disable the module without removing the call | `bool` | `true` | no |
| <a name="input_fairness"></a> [fairness](#input\_fairness) | Fairness configuration. Task queue fairness is disabled unless enabled here. Once set it cannot be removed — disable with `task_queue_fairness_enabled = false` rather than dropping the variable | <pre>object({<br/>    task_queue_fairness_enabled = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the namespace. Must be 2-64 characters, start with a letter, contain only lowercase letters, numbers and hyphens, and not end with a hyphen. Pass `""` when `create_namespace` is `false` | `string` | n/a | yes |
| <a name="input_namespace_lifecycle"></a> [namespace\_lifecycle](#input\_namespace\_lifecycle) | Temporal Cloud lifecycle settings such as delete protection. Unrelated to Terraform's own `lifecycle` meta-argument. Delete protection is off when omitted, and must be set back to `false` and applied before `terraform destroy` can succeed | <pre>object({<br/>    enable_delete_protection = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Regions the namespace is available in, as cloud-provider-prefixed IDs (for example `aws-us-east-1`, not `us-east-1`). Pass one region, or two to provision a high availability namespace replicated across both. Available regions differ per account — query the `temporalcloud_regions` data source to list the ones yours can use. Regions cannot be changed after creation. Pass `[]` when `create_namespace` is `false` | `list(string)` | n/a | yes |
| <a name="input_retention_days"></a> [retention\_days](#input\_retention\_days) | Number of days to retain workflow history. Optional — defaults to 30. Changes apply to all new running workflows | `number` | `30` | no |
| <a name="input_search_attributes"></a> [search\_attributes](#input\_search\_attributes) | Custom search attributes, as a map of name => type. Valid types are `bool`, `datetime`, `double`, `int`, `keyword`, `keyword_list` and `text`, matched case-insensitively. Search attributes cannot be deleted once created, so removing an entry will not remove it from the namespace | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the namespace. Keys must be lowercase. This replaces the namespace's entire tag set, so tags added outside Terraform are removed on the next apply | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create and delete timeouts, as duration strings such as `30s` or `2h45m`. The provider's own defaults — 10 minutes to create, 5 minutes to delete — apply to whichever is omitted | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_endpoints"></a> [namespace\_endpoints](#output\_namespace\_endpoints) | All endpoints for the namespace (gRPC, mTLS gRPC and Web UI addresses) |
| <a name="output_namespace_grpc_address"></a> [namespace\_grpc\_address](#output\_namespace\_grpc\_address) | The gRPC address for API key client connections, for example `aws-us-east-1.aws.api.temporal.io:7233`. This is a **regional** address shared by every namespace in the region, so it does not identify the namespace — clients using API key authentication also send the namespace name. Returned whether or not `api_key_auth` is set, so its presence does not indicate that API key authentication is enabled |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The unique identifier of the namespace across all Temporal Cloud tenants, in the form `<namespace>.<account_id>` |
| <a name="output_namespace_mtls_grpc_address"></a> [namespace\_mtls\_grpc\_address](#output\_namespace\_mtls\_grpc\_address) | The gRPC address for mTLS client connections, for example `my-namespace.a1b2c.tmprl.cloud:7233`. Unlike the API key address this is specific to the namespace. Returned whether or not `accepted_client_ca` is set, so its presence does not indicate that mTLS is enabled |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | The name of the namespace |
| <a name="output_namespace_regions"></a> [namespace\_regions](#output\_namespace\_regions) | The regions the namespace is available in |
| <a name="output_namespace_search_attributes"></a> [namespace\_search\_attributes](#output\_namespace\_search\_attributes) | Map of custom search attribute name => type created on the namespace |
| <a name="output_namespace_tags"></a> [namespace\_tags](#output\_namespace\_tags) | The complete set of tags applied to the namespace |
| <a name="output_namespace_web_address"></a> [namespace\_web\_address](#output\_namespace\_web\_address) | The address of the namespace in the Temporal Cloud Web UI |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, how the test layers are arranged,
and the Temporal Cloud API behaviours the tests exist to guard against.

## License

Apache-2.0 licensed. See [LICENSE](LICENSE).
