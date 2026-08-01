// Certificate-based authentication: accepted_client_ca and certificate_filters.
//
// A separate file so it gets its own state and its own namespace. Files run
// sequentially and each is torn down before the next begins, so only one
// namespace exists at a time.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "create_mtls_namespace" {
  variables {
    name           = "${run.setup.namespace_name}-mtls"
    regions        = [run.setup.region]
    retention_days = 1

    // The provider expects the CA bundle Base64-encoded.
    accepted_client_ca = base64encode(run.setup.ca_certificate_pem)

    certificate_filters = [
      {
        common_name              = "worker.example.com"
        organization             = "Terraform Test"
        organizational_unit      = "platform"
        subject_alternative_name = "worker.example.com"
      },
    ]
  }

  assert {
    condition     = output.namespace_name == "${run.setup.namespace_name}-mtls"
    error_message = "namespace_name output did not echo the requested name"
  }

  // The point of the whole file: with mTLS configured, Temporal Cloud must return
  // an mTLS gRPC endpoint. This is what certificate-authenticated workers connect
  // to, and it is empty on an API-key-only namespace.
  assert {
    condition     = output.namespace_mtls_grpc_address != ""
    error_message = "namespace_mtls_grpc_address is empty despite accepted_client_ca being set"
  }

  assert {
    condition     = output.namespace_web_address != ""
    error_message = "namespace_web_address is empty"
  }
}
