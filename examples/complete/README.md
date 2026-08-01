# Complete Temporal Cloud namespace example

Configuration in this directory creates a Temporal Cloud namespace with API key authentication,
capacity and fairness settings, a codec server, custom search attributes and tags.

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

The `codec_server.endpoint` points at a placeholder host. Temporal Cloud accepts the configuration
without reaching the server, but the UI will report a decode error until you point it at a real codec
server.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_namespace"></a> [namespace](#module\_namespace) | terraform-temporalcloud-modules/namespace/temporalcloud | ~> 2.0 |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_grpc_address"></a> [namespace\_grpc\_address](#output\_namespace\_grpc\_address) | The gRPC address workers and clients connect to |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The unique identifier of the namespace |
| <a name="output_namespace_search_attributes"></a> [namespace\_search\_attributes](#output\_namespace\_search\_attributes) | The custom search attributes created on the namespace |
| <a name="output_namespace_tags"></a> [namespace\_tags](#output\_namespace\_tags) | The complete tag set applied to the namespace |
| <a name="output_namespace_web_address"></a> [namespace\_web\_address](#output\_namespace\_web\_address) | The namespace in the Temporal Cloud Web UI |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
