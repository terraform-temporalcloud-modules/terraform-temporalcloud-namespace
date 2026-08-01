// Verifies create_namespace = false against a real provider.
//
// Separate file so it gets its own state and cannot interfere with the namespace
// created in namespace.tftest.hcl. Creates no resources, so it is cheap — but it
// still configures the provider, which is why it needs TEMPORAL_CLOUD_API_KEY.

provider "temporalcloud" {}

run "creates_nothing" {
  variables {
    create_namespace = false
  }

  // Every output is count-gated behind try(); these assertions prove the
  // fallbacks evaluate rather than erroring when the module is switched off.
  assert {
    condition     = output.namespace_id == ""
    error_message = "namespace_id should fall back to empty when create_namespace = false"
  }

  assert {
    condition     = output.namespace_name == ""
    error_message = "namespace_name should fall back to empty when create_namespace = false"
  }

  assert {
    condition     = output.namespace_regions == tolist([])
    error_message = "namespace_regions should fall back to an empty list"
  }

  assert {
    condition     = output.namespace_grpc_address == ""
    error_message = "namespace_grpc_address should fall back to empty"
  }

  assert {
    condition     = output.namespace_mtls_grpc_address == ""
    error_message = "namespace_mtls_grpc_address should fall back to empty"
  }

  assert {
    condition     = output.namespace_web_address == ""
    error_message = "namespace_web_address should fall back to empty"
  }

  assert {
    condition     = length(output.namespace_search_attributes) == 0
    error_message = "namespace_search_attributes should fall back to an empty map"
  }

  assert {
    condition     = length(output.namespace_tags) == 0
    error_message = "namespace_tags should fall back to an empty map"
  }

  assert {
    condition     = length(output.namespace_endpoints) == 0
    error_message = "namespace_endpoints should fall back to an empty map"
  }
}
