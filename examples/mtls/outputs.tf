output "namespace_id" {
  description = "The unique identifier of the namespace"
  value       = module.namespace.namespace_id
}

output "namespace_mtls_grpc_address" {
  description = "The gRPC address mTLS clients connect to"
  value       = module.namespace.namespace_mtls_grpc_address
}

output "ca_certificate_pem" {
  description = "The generated CA certificate. Client certificates must be signed by this CA to connect"
  value       = tls_self_signed_cert.ca.cert_pem
}
