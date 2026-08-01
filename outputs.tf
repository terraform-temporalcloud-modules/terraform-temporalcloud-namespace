################################################################################
# Namespace
#
# Outputs are wrapped in `try()` so they still evaluate to an empty value when
# `create_namespace = false` leaves no resource to reference.
################################################################################

output "namespace_id" {
  description = "The unique identifier of the namespace across all Temporal Cloud tenants, in the form `<namespace>.<account_id>`"
  value       = try(temporalcloud_namespace.this[0].id, "")
}

output "namespace_name" {
  description = "The name of the namespace"
  value       = try(temporalcloud_namespace.this[0].name, "")
}

output "namespace_regions" {
  description = "The regions the namespace is available in"
  value       = try(temporalcloud_namespace.this[0].regions, [])
}

################################################################################
# Endpoints
#
# Exposed both as a whole and individually, since worker and client
# configuration usually needs a single address rather than the full object.
################################################################################

output "namespace_endpoints" {
  description = "All endpoints for the namespace (gRPC, mTLS gRPC and Web UI addresses)"
  value       = try(temporalcloud_namespace.this[0].endpoints, {})
}

output "namespace_grpc_address" {
  description = "The gRPC address for API key client connections, for example `aws-us-east-1.aws.api.temporal.io:7233`. This is a **regional** address shared by every namespace in the region, so it does not identify the namespace — clients using API key authentication also send the namespace name. Returned whether or not `api_key_auth` is set, so its presence does not indicate that API key authentication is enabled"
  value       = try(temporalcloud_namespace.this[0].endpoints.grpc_address, "")
}

output "namespace_mtls_grpc_address" {
  description = "The gRPC address for mTLS client connections, for example `my-namespace.a1b2c.tmprl.cloud:7233`. Unlike the API key address this is specific to the namespace. Returned whether or not `accepted_client_ca` is set, so its presence does not indicate that mTLS is enabled"
  value       = try(temporalcloud_namespace.this[0].endpoints.mtls_grpc_address, "")
}

output "namespace_web_address" {
  description = "The address of the namespace in the Temporal Cloud Web UI"
  value       = try(temporalcloud_namespace.this[0].endpoints.web_address, "")
}

################################################################################
# Search attributes and tags
################################################################################

output "namespace_search_attributes" {
  description = "Map of custom search attribute name => type created on the namespace"
  value       = try({ for k, v in temporalcloud_namespace_search_attribute.this : k => v.type }, {})
}

output "namespace_tags" {
  description = "The complete set of tags applied to the namespace"
  value       = try(temporalcloud_namespace_tags.this[0].tags, {})
}
