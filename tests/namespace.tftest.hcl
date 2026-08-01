// Main lifecycle: create a namespace with every input that can be applied to a
// single-region API-key namespace, then update it in place to add the child
// resources.
//
// Creates ONE namespace and updates it across run blocks rather than one per
// case. Run blocks share state within a file, so a later block with different
// variables updates the namespace instead of creating another.
//
// terraform test destroys everything it created when the file finishes, including
// after a failed assertion.

provider "temporalcloud" {
  // Reads TEMPORAL_CLOUD_API_KEY from the environment. The module under test
  // declares no provider block, by design for a published module, so the test
  // supplies one.
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

// Public connectivity rule fixture, so connectivity_rule_ids can be exercised.
run "connectivity" {
  module {
    source = "./tests/connectivity"
  }
}

run "create_namespace" {
  variables {
    name           = run.setup.namespace_name
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true

    capacity = {
      mode = "on_demand"
    }

    codec_server = {
      endpoint                         = "https://codec.example.com"
      custom_error_link                = "https://example.com/help"
      custom_error_message             = "Unable to decode payloads."
      include_cross_origin_credentials = true
      pass_access_token                = true
    }

    fairness = {
      task_queue_fairness_enabled = true
    }

    connectivity_rule_ids = [run.connectivity.connectivity_rule_id]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
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
    // Elementwise, not ==: the output comes from try(..., []) so it is a tuple,
    // which never compares equal to a list.
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

// Updates the SAME namespace, adding the child resources this module folds in.
run "add_search_attributes_and_tags" {
  variables {
    name           = run.setup.namespace_name
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true

    capacity = {
      mode = "on_demand"
    }

    codec_server = {
      endpoint                         = "https://codec.example.com"
      custom_error_link                = "https://example.com/help"
      custom_error_message             = "Unable to decode payloads."
      include_cross_origin_credentials = true
      pass_access_token                = true
    }

    fairness = {
      task_queue_fairness_enabled = true
    }

    connectivity_rule_ids = [run.connectivity.connectivity_rule_id]

    timeouts = {
      create = "10m"
      delete = "10m"
    }

    // One of every type the module accepts, to confirm the API agrees.
    search_attributes = {
      CustomerId  = "keyword"
      OrderTotal  = "double"
      IsPriority  = "bool"
      SubmittedAt = "datetime"
      Labels      = "keyword_list"
      Notes       = "text"
      Attempts    = "int"
    }

    // Tag keys must be lowercase; the API rejects mixed case with
    // "tag key contains invalid characters". `managed-by` covers separators,
    // which the provider does not document either way.
    tags = {
      environment  = "test"
      "managed-by" = "terraform"
    }
  }

  assert {
    condition     = length(output.namespace_search_attributes) == 7
    error_message = "expected 7 search attributes, got ${length(output.namespace_search_attributes)}"
  }

  assert {
    condition     = output.namespace_search_attributes["CustomerId"] == "keyword"
    error_message = "CustomerId search attribute did not come back as keyword"
  }

  assert {
    condition     = output.namespace_search_attributes["Labels"] == "keyword_list"
    error_message = "Labels search attribute did not come back as keyword_list"
  }

  assert {
    condition     = output.namespace_search_attributes["Attempts"] == "int"
    error_message = "Attempts search attribute did not come back as int"
  }

  // Elementwise rather than == against tomap(...): the output comes from
  // try(x, {}), and an object never compares equal to a map.
  assert {
    condition     = length(output.namespace_tags) == 2
    error_message = "expected 2 tags, got ${length(output.namespace_tags)}"
  }

  assert {
    condition     = output.namespace_tags["environment"] == "test"
    error_message = "environment tag did not round-trip through the API"
  }

  assert {
    condition     = output.namespace_tags["managed-by"] == "terraform"
    error_message = "hyphenated tag key did not round-trip through the API"
  }

  // Updating children must not have replaced the namespace.
  assert {
    condition     = output.namespace_name == run.setup.namespace_name
    error_message = "namespace was replaced rather than updated in place"
  }
}
