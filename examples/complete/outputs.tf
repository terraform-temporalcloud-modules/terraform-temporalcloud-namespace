output "namespace_id" {
  description = "The unique identifier of the namespace"
  value       = module.namespace.namespace_id
}

output "namespace_grpc_address" {
  description = "The gRPC address workers and clients connect to"
  value       = module.namespace.namespace_grpc_address
}

output "namespace_web_address" {
  description = "The namespace in the Temporal Cloud Web UI"
  value       = module.namespace.namespace_web_address
}

output "namespace_search_attributes" {
  description = "The custom search attributes created on the namespace"
  value       = module.namespace.namespace_search_attributes
}

output "namespace_tags" {
  description = "The complete tag set applied to the namespace"
  value       = module.namespace.namespace_tags
}
