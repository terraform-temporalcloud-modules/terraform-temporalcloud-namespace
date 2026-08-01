// High availability namespace: two regions.
//
// The provider's documentation is inconsistent about this. The namespace resource
// describes two regions as a replicated high availability configuration, while the
// namespaces data source states that multi-region namespaces are "currently
// unsupported by the Terraform provider". This test establishes which holds, since
// the module's README documents two regions as a supported pattern.
//
// Requires an account entitled to at least two regions; `run.setup.ha_regions` is
// empty otherwise and the assertion below reports that rather than failing
// obscurely against the API.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "requires_two_regions" {
  module {
    source = "./tests/setup"
  }

  assert {
    condition     = length(output.ha_regions) == 2
    error_message = "This account is entitled to fewer than two regions, so a high availability namespace cannot be tested. Entitled regions: ${join(", ", output.available_regions)}"
  }
}

run "create_ha_namespace" {
  variables {
    name           = "${run.setup.namespace_name}-ha"
    regions        = run.setup.ha_regions
    retention_days = 1
    api_key_auth   = true
  }

  assert {
    condition     = length(output.namespace_regions) == 2
    error_message = "expected a namespace replicated across 2 regions, got ${length(output.namespace_regions)}"
  }

  // Order is not asserted: the provider ignores region ordering changes, which
  // occur naturally on failover.
  assert {
    condition     = length(setsubtract(toset(run.setup.ha_regions), toset(output.namespace_regions))) == 0
    error_message = "namespace_regions did not contain both requested regions"
  }

  assert {
    condition     = output.namespace_grpc_address != ""
    error_message = "namespace_grpc_address is empty despite api_key_auth = true"
  }
}
