// Apply-based tests against a REAL Temporal Cloud account.
//
// These create and destroy real namespaces and bill the account. They need
// TEMPORAL_CLOUD_API_KEY and are therefore NOT part of the PR gate — see
// .github/workflows/test.yml, which runs them on demand.
//
// Deliberately creates ONE namespace and updates it in place across run blocks
// rather than creating one per case: namespace creation is slow and Temporal Cloud
// accounts cap how many can exist. Run blocks share state within a file, so a
// later block with different variables is an update, not a new namespace.
//
// terraform test destroys everything it created when the file finishes, including
// after a failed assertion.

provider "temporalcloud" {
  // Reads TEMPORAL_CLOUD_API_KEY from the environment. The module under test
  // declares no provider block, by design for a published module, so the test
  // supplies one.
}

// Unique name so repeat and concurrent runs do not collide.
run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "create_namespace" {
  variables {
    name           = run.setup.namespace_name
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true
  }

  assert {
    condition     = output.namespace_name == run.setup.namespace_name
    error_message = "namespace_name output did not echo the requested name"
  }

  // The provider documents the ID as <namespace>.<account_id>.
  assert {
    condition     = startswith(output.namespace_id, "${run.setup.namespace_name}.")
    error_message = "namespace_id should be '<name>.<account_id>', got: ${output.namespace_id}"
  }

  assert {
    // Compared elementwise, not with ==: the output comes from try(..., []) so it is
    // a tuple, and tuple == list is false even when the contents match.
    condition     = length(output.namespace_regions) == 1 && output.namespace_regions[0] == run.setup.region
    error_message = "namespace_regions did not match the requested region"
  }

  // With api_key_auth enabled, Temporal Cloud must return a gRPC endpoint —
  // this is the value workers and clients actually connect to.
  assert {
    condition     = output.namespace_grpc_address != ""
    error_message = "namespace_grpc_address is empty despite api_key_auth = true"
  }

  assert {
    condition     = output.namespace_web_address != ""
    error_message = "namespace_web_address is empty"
  }

  // No search attributes or tags requested yet.
  assert {
    condition     = length(output.namespace_search_attributes) == 0
    error_message = "expected no search attributes before any were requested"
  }

  assert {
    condition     = length(output.namespace_tags) == 0
    error_message = "expected no tags before any were requested"
  }
}

// Updates the SAME namespace. Proves the folded-in child resources attach to an
// existing namespace, which is the whole reason they live in this module.
run "add_search_attributes_and_tags" {
  variables {
    name           = run.setup.namespace_name
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true

    search_attributes = {
      CustomerId  = "Keyword"
      OrderTotal  = "Double"
      IsPriority  = "Bool"
      SubmittedAt = "Datetime"
      Labels      = "KeywordList"
      Notes       = "Text"
      Attempts    = "Int"
    }

    tags = {
      Environment = "test"
      ManagedBy   = "terraform"
    }
  }

  // Every search attribute type the module claims to support was accepted by the
  // API, not merely by terraform validate.
  assert {
    condition     = length(output.namespace_search_attributes) == 7
    error_message = "expected 7 search attributes, got ${length(output.namespace_search_attributes)}"
  }

  assert {
    condition     = output.namespace_search_attributes["CustomerId"] == "Keyword"
    error_message = "CustomerId search attribute did not come back as Keyword"
  }

  assert {
    condition     = output.namespace_search_attributes["Attempts"] == "Int"
    error_message = "Attempts search attribute did not come back as Int"
  }

  assert {
    condition     = output.namespace_tags == tomap({ Environment = "test", ManagedBy = "terraform" })
    error_message = "namespace_tags did not round-trip through the API"
  }

  // Updating children must not have replaced the namespace.
  assert {
    condition     = output.namespace_name == run.setup.namespace_name
    error_message = "namespace was replaced rather than updated in place"
  }
}
