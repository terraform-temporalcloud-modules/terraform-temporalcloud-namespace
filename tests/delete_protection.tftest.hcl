// namespace_lifecycle.enable_delete_protection.
//
// Isolated in its own file on purpose. Delete protection makes the namespace
// undeletable while enabled, so if teardown ran with it on, terraform test could
// not destroy the namespace and would leave a permanent orphan requiring manual
// cleanup.
//
// The final run block therefore turns protection back off, and carries no
// assertions that could fail before that change is applied. Keeping this in its
// own file also means a failure here cannot block teardown of any other test's
// namespace.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "enable_delete_protection" {
  variables {
    name           = "${run.setup.namespace_name}-prot"
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true

    namespace_lifecycle = {
      enable_delete_protection = true
    }
  }

  assert {
    condition     = output.namespace_id != ""
    error_message = "namespace was not created with delete protection enabled"
  }
}

// Must run, and must succeed, for teardown to be able to destroy the namespace.
// Deliberately assertion-free.
run "disable_delete_protection" {
  variables {
    name           = "${run.setup.namespace_name}-prot"
    regions        = [run.setup.region]
    retention_days = 1
    api_key_auth   = true

    namespace_lifecycle = {
      enable_delete_protection = false
    }
  }
}
