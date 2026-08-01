# Referencing every output forces Terraform to evaluate each one, so a broken
# output expression fails validation here rather than in a consumer's plan.

output "all_inputs" {
  description = "Every output of the fully configured module instance"
  value = {
    namespace_id                = module.all_inputs.namespace_id
    namespace_name              = module.all_inputs.namespace_name
    namespace_regions           = module.all_inputs.namespace_regions
    namespace_endpoints         = module.all_inputs.namespace_endpoints
    namespace_grpc_address      = module.all_inputs.namespace_grpc_address
    namespace_mtls_grpc_address = module.all_inputs.namespace_mtls_grpc_address
    namespace_web_address       = module.all_inputs.namespace_web_address
    namespace_search_attributes = module.all_inputs.namespace_search_attributes
    namespace_tags              = module.all_inputs.namespace_tags
  }
}

output "disabled" {
  description = "Outputs when create_namespace is false — every one must fall back rather than error"
  value = {
    namespace_id                = module.disabled.namespace_id
    namespace_name              = module.disabled.namespace_name
    namespace_regions           = module.disabled.namespace_regions
    namespace_endpoints         = module.disabled.namespace_endpoints
    namespace_grpc_address      = module.disabled.namespace_grpc_address
    namespace_mtls_grpc_address = module.disabled.namespace_mtls_grpc_address
    namespace_web_address       = module.disabled.namespace_web_address
    namespace_search_attributes = module.disabled.namespace_search_attributes
    namespace_tags              = module.disabled.namespace_tags
  }
}

output "minimal" {
  description = "Outputs from the minimum viable module call"
  value       = module.minimal.namespace_id
}

output "wrapper" {
  description = "Wrapper outputs, keyed by item name"
  value       = module.wrapper.wrapper
}
