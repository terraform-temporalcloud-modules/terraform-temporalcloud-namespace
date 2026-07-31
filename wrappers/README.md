# Wrapper for the Temporal Cloud namespace module

The configuration in `wrappers/` implements the single module wrapper pattern, which allows managing
several copies of this module from one call in places where the native `for_each` on a module block is
not available — most commonly Terragrunt.

This wrapper adds no functionality of its own. Every key under `items` accepts any input the root
module accepts, and `defaults` supplies values shared by all items.

> **Maintenance.** These files are hand-maintained. Upstream's
> `terraform_wrapper_module_for_each` pre-commit hook is deliberately not used, because it overwrites
> this README on every run with an AWS S3 example whose variables do not exist in this module — see
> the comment in `.pre-commit-config.yaml`. When you add a variable to the root module, add a matching
> line to `wrappers/main.tf`; the `wrapper-sync` hook fails the build if you forget.

## Usage with Terraform

```hcl
module "namespaces" {
  source = "terraform-temporalcloud-modules/namespace/temporalcloud//wrappers"

  # Shared by every item unless the item overrides it.
  defaults = {
    regions        = ["aws-us-east-1"]
    retention_days = 30
    api_key_auth   = true

    tags = {
      Terraform = "true"
    }
  }

  items = {
    orders = {
      name = "orders-prod"

      search_attributes = {
        CustomerId = "Keyword"
        OrderTotal = "Double"
      }
    }

    payments = {
      name           = "payments-prod"
      retention_days = 90 # overrides the default above
    }

    # Two regions provisions a high availability namespace.
    audit = {
      name    = "audit-prod"
      regions = ["aws-us-east-1", "aws-us-west-2"]
    }
  }
}
```

Outputs are keyed by the same map keys:

```hcl
output "orders_grpc_address" {
  value = module.namespaces.wrapper["orders"].namespace_grpc_address
}
```

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-temporalcloud-modules/namespace/temporalcloud//wrappers?version=1.0.0"
  # Alternative source:
  # source = "git::git@github.com:terraform-temporalcloud-modules/terraform-temporalcloud-namespace.git//wrappers?ref=v1.0.0"
}

inputs = {
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

Pin `?version=` / `?ref=` to a released tag rather than a branch, so a wrapper upgrade is a deliberate
change.

## Inputs

| Name | Description | Type | Default |
| ---- | ----------- | ---- | ------- |
| `defaults` | Map of default values applied to every item | `any` | `{}` |
| `items` | Map of items to create; values are passed through to the module | `any` | `{}` |

## Outputs

| Name | Description |
| ---- | ----------- |
| `wrapper` | Map of module outputs, keyed by the same keys as `items` |
