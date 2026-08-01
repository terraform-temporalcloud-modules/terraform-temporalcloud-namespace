provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

################################################################################
# Local regression coverage
#
# The examples/ directories source the PUBLISHED module so they are copy-pasteable
# for consumers. That means they validate the last release, not the code in this
# repo — a renamed or removed variable would slip through CI unnoticed.
#
# This directory closes that gap: it sources the module by relative path and
# passes EVERY input, so `terraform validate` fails here the moment the variable
# surface changes incompatibly. CI picks it up automatically because it contains a
# versions.tf with required_version.
#
# When you add a variable to the root module, add it here in the same PR. Adding
# it to examples/ has to wait until the next release publishes it.
################################################################################

# Every input the module accepts.
module "all_inputs" {
  source = "../../"

  create_namespace = true

  name           = "yulei-tflocal-test"
  regions        = ["aws-us-east-1"]
  retention_days = 14

  api_key_auth       = true
  accepted_client_ca = null

  certificate_filters = [
    {
      common_name              = "worker.example.com"
      organization             = "Example Org"
      organizational_unit      = "platform"
      subject_alternative_name = "worker.example.com"
    },
  ]

  capacity = {
    mode  = "provisioned"
    value = 10
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

  namespace_lifecycle = {
    enable_delete_protection = false
  }

  connectivity_rule_ids = []

  timeouts = {
    create = "10m"
    delete = "10m"
  }

  search_attributes = {
    CustomerId  = "keyword"
    OrderTotal  = "double"
    IsPriority  = "bool"
    SubmittedAt = "datetime"
    Labels      = "keyword_list"
    Notes       = "text"
    Attempts    = "int"
  }

  tags = {
    terraform = "true"
  }
}

# The create flag off: proves the module produces no resources and that every
# output still evaluates via its try() fallback.
module "disabled" {
  source = "../../"

  create_namespace = false

  # name and regions have no defaults, so Terraform requires them even when
  # nothing is created. These empty values are never read.
  name    = ""
  regions = []
}

# Minimum viable call: only the three required-in-practice inputs.
module "minimal" {
  source = "../../"

  name           = "yulei-tflocal-minimal"
  regions        = ["aws-us-east-1"]
  retention_days = 1
}

# The wrapper, exercised through the local path as well.
module "wrapper" {
  source = "../../wrappers"

  defaults = {
    regions        = ["aws-us-east-1"]
    retention_days = 30
    api_key_auth   = true
  }

  items = {
    orders   = { name = "yulei-tflocal-orders" }
    payments = { name = "yulei-tflocal-payments", retention_days = 90 }
  }
}
