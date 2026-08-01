// The wrappers submodule: several namespaces from one call, with per-item
// overrides of the shared defaults.
//
// This is the only test that creates more than one namespace at a time, which is
// the behaviour it exists to verify.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "create_many" {
  module {
    source = "./wrappers"
  }

  variables {
    defaults = {
      regions        = [run.setup.region]
      retention_days = 1
      api_key_auth   = true

      tags = {
        environment = "test"
      }
    }

    items = {
      orders = {
        name = "${run.setup.namespace_name}-orders"

        search_attributes = {
          CustomerId = "keyword"
        }
      }

      payments = {
        name = "${run.setup.namespace_name}-payments"
        // Overrides the shared default above.
        retention_days = 2
      }
    }
  }

  assert {
    condition     = length(output.wrapper) == 2
    error_message = "expected 2 namespaces from the wrapper, got ${length(output.wrapper)}"
  }

  assert {
    condition     = output.wrapper["orders"].namespace_name == "${run.setup.namespace_name}-orders"
    error_message = "the orders item did not take its own name"
  }

  // Shared defaults reach every item.
  assert {
    condition     = output.wrapper["orders"].namespace_tags["environment"] == "test"
    error_message = "defaults.tags did not reach the orders item"
  }

  assert {
    condition     = output.wrapper["payments"].namespace_name == "${run.setup.namespace_name}-payments"
    error_message = "the payments item did not take its own name"
  }

  // Two distinct namespaces, not the same one reported twice.
  assert {
    condition     = output.wrapper["orders"].namespace_id != output.wrapper["payments"].namespace_id
    error_message = "both wrapper items resolved to the same namespace"
  }

  // Per-item values reach the item that asked for them...
  assert {
    condition     = length(output.wrapper["orders"].namespace_search_attributes) == 1
    error_message = "per-item search_attributes did not reach the orders item"
  }

  // ...and only that item. Without this second half, a wrapper that broadcast
  // every per-item value to every item would still pass.
  assert {
    condition     = length(output.wrapper["payments"].namespace_search_attributes) == 0
    error_message = "the payments item got search attributes it never asked for"
  }

  // `payments` overrides defaults.retention_days to 2. The module exposes no
  // retention output, so that override is applied but cannot be asserted — see
  // tests/README.md. The shared default reaching the item IS checkable.
  assert {
    condition     = output.wrapper["payments"].namespace_tags["environment"] == "test"
    error_message = "defaults.tags did not reach the payments item"
  }
}
