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

  // The endpoints do NOT reveal whether mTLS is configured. Temporal Cloud returns
  // all three on every namespace: namespace.tftest.hcl creates one with
  // api_key_auth = true and no CA at all, and it still reports a populated
  // mtls_grpc_address. An assertion that the address is merely non-empty would
  // pass on that namespace too, so it would prove nothing here.
  //
  // What is checkable is that the address is a host for THIS namespace.
  assert {
    condition     = startswith(output.namespace_mtls_grpc_address, "${output.namespace_id}.")
    error_message = "namespace_mtls_grpc_address is not a host for this namespace: ${output.namespace_mtls_grpc_address}"
  }

  assert {
    condition     = strcontains(output.namespace_web_address, output.namespace_id)
    error_message = "namespace_web_address is not a URL for this namespace: ${output.namespace_web_address}"
  }

  // What this file actually proves about mTLS is that the API ACCEPTS the
  // configuration: a Base64-encoded CA bundle plus a certificate_filters list in
  // the shape the module builds. That is carried by the apply succeeding — a
  // wrongly encoded CA or a mis-nested filter fails the run before any assertion
  // is reached. The module surfaces no output echoing either input, so there is
  // nothing further to assert; tests/README.md records the limitation.
}
