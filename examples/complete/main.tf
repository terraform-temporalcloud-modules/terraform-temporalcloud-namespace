provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"

  tags = {
    Example   = local.name
    Terraform = "true"
  }
}

################################################################################
# Complete: every input this module supports
################################################################################

module "namespace" {
  source = "../../"

  name = local.name

  # A single region. Add a second to provision a high availability namespace
  # replicated across both — see the `regions` variable for the constraint.
  regions        = ["aws-us-east-1"]
  retention_days = 14

  # API key auth is the simpler of the two auth modes; see the `mtls` example for
  # certificate-based authentication.
  api_key_auth = true

  capacity = {
    mode = "on_demand"
  }

  fairness = {
    task_queue_fairness_enabled = true
  }

  namespace_lifecycle = {
    # Left false so `terraform destroy` works for an example. Turn this on for
    # anything you would be upset to lose.
    enable_delete_protection = false
  }

  codec_server = {
    endpoint             = "https://codec.example.com"
    pass_access_token    = true
    custom_error_message = "Unable to decode payloads. Check the codec server is reachable."
  }

  timeouts = {
    create = "10m"
    delete = "10m"
  }

  # Folded into this module because the resource is keyed by namespace_id.
  search_attributes = {
    CustomerId  = "Keyword"
    OrderTotal  = "Double"
    IsPriority  = "Bool"
    SubmittedAt = "Datetime"
    Labels      = "KeywordList"
  }

  tags = local.tags
}

################################################################################
# Disabled: proves `create_namespace = false` produces no resources
################################################################################

module "namespace_disabled" {
  source = "../../"

  create_namespace = false
}
