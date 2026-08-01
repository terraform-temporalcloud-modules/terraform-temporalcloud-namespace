# mTLS Temporal Cloud namespace example

Configuration in this directory creates a Temporal Cloud namespace that authenticates clients with
mutual TLS instead of API keys.

The example generates a self-signed CA with the `tls` provider so it runs with no external setup.
Temporal Cloud only ever receives the CA *certificate* — the private key stays in Terraform state. In
production, replace the generated CA with one issued by your own PKI.

The `regions` value must be one your account is entitled to use — see
[Choosing regions](../../README.md#choosing-regions) if apply reports an invalid region.

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan
terraform apply
```

Note that this example creates resources which cost money. Run `terraform destroy` when you no longer
need them.

Because the CA private key is stored in Terraform state, treat the state for this example as
sensitive. For real workloads, generate the CA outside Terraform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_namespace"></a> [namespace](#module\_namespace) | terraform-temporalcloud-modules/namespace/temporalcloud | ~> 2.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ca_certificate_pem"></a> [ca\_certificate\_pem](#output\_ca\_certificate\_pem) | The generated CA certificate. Client certificates must be signed by this CA to connect |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The unique identifier of the namespace |
| <a name="output_namespace_mtls_grpc_address"></a> [namespace\_mtls\_grpc\_address](#output\_namespace\_mtls\_grpc\_address) | The gRPC address mTLS clients connect to |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
