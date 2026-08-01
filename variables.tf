variable "create_namespace" {
  description = "Controls if the namespace should be created. Set to `false` to disable the module without removing the call"
  type        = bool
  default     = true
}

################################################################################
# Namespace
################################################################################

variable "name" {
  description = "The name of the namespace. Must be 2-64 characters, start with a letter, contain only lowercase letters, numbers and hyphens, and not end with a hyphen. Required unless `create_namespace` is `false`"
  type        = string
  default     = ""

  # Mirrors the provider's constraint so a malformed name fails during plan
  # rather than after a round trip to the Temporal Cloud API.
  validation {
    condition     = var.name == "" || can(regex("^[a-z][a-z0-9-]{0,62}[a-z0-9]$", var.name))
    error_message = "The namespace name must be 2-64 characters, start with a letter, contain only lowercase letters, numbers and hyphens, and not end with a hyphen."
  }
}

variable "regions" {
  description = "Regions the namespace is available in, as cloud-provider-prefixed IDs (for example `aws-us-east-1`, not `us-east-1`). Pass one region, or two to provision a high availability namespace replicated across both. Available regions differ per account — query the `temporalcloud_regions` data source to list the ones yours can use. Regions cannot be changed after creation"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.regions) <= 2
    error_message = "A namespace supports at most two regions. Two regions creates a high availability namespace."
  }
}

variable "retention_days" {
  description = "Number of days to retain workflow history. Changes apply to all new running workflows"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 1
    error_message = "The retention period must be at least 1 day."
  }
}

################################################################################
# Authentication
#
# A namespace needs at least one method: set `api_key_auth`, or supply
# `accepted_client_ca` for mTLS. Both may be enabled at once.
################################################################################

variable "api_key_auth" {
  description = "Enables API key authentication for this namespace"
  type        = bool
  default     = null
}

variable "accepted_client_ca" {
  description = "Base64-encoded CA certificate in PEM format that clients present when authenticating. Required for mTLS authentication, for example `base64encode(file(\"ca.pem\"))`"
  type        = string
  default     = null
}

variable "certificate_filters" {
  description = "Filters applied to client certificates. When set, connections are accepted only from certificates whose distinguished name matches at least one filter. Omit rather than passing an empty list"
  type = list(object({
    common_name              = optional(string)
    organization             = optional(string)
    organizational_unit      = optional(string)
    subject_alternative_name = optional(string)
  }))
  default = null

  validation {
    condition     = try(length(var.certificate_filters) > 0, true)
    error_message = "Empty certificate filter lists are not accepted by the provider. Omit the variable instead."
  }
}

################################################################################
# Namespace configuration
################################################################################

variable "capacity" {
  description = "Capacity configuration. `mode` is `provisioned` or `on_demand`; `value` is required when mode is `provisioned`"
  type = object({
    mode  = optional(string)
    value = optional(number)
  })
  default = null

  # try() covers both a null object and an omitted mode: contains() errors on a
  # null value, so `capacity = { value = 10 }` must not reach it.
  validation {
    condition     = try(contains(["provisioned", "on_demand"], var.capacity.mode), true)
    error_message = "Capacity mode must be one of: provisioned, on_demand."
  }

  validation {
    condition     = try(var.capacity.mode, null) != "provisioned" || try(var.capacity.value, null) != null
    error_message = "Capacity value must be set when capacity mode is 'provisioned'."
  }
}

variable "codec_server" {
  description = "Codec server the Temporal Cloud UI uses to decode payloads for everyone viewing this namespace, including when the workflow history itself is encrypted"
  type = object({
    endpoint                         = string
    custom_error_link                = optional(string)
    custom_error_message             = optional(string)
    include_cross_origin_credentials = optional(bool)
    pass_access_token                = optional(bool)
  })
  default = null

  validation {
    condition     = try(startswith(var.codec_server.endpoint, "https"), true)
    error_message = "The codec server endpoint must begin with \"https\"."
  }
}

variable "fairness" {
  description = "Fairness configuration. Task queue fairness is disabled unless enabled here"
  type = object({
    task_queue_fairness_enabled = optional(bool)
  })
  default = null

}

variable "namespace_lifecycle" {
  description = "Temporal Cloud lifecycle settings such as delete protection. Unrelated to Terraform's own `lifecycle` meta-argument. Delete protection must be set back to `false` and applied before `terraform destroy` can succeed"
  type = object({
    enable_delete_protection = optional(bool)
  })
  default = null
}

variable "connectivity_rule_ids" {
  description = "IDs of connectivity rules to attach to this namespace"
  type        = set(string)
  default     = null
}

variable "timeouts" {
  description = "Create and delete timeouts, as duration strings such as `30s` or `2h45m`"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}

################################################################################
# Search attributes
#
# Managed here rather than as a separate module: the underlying resource is keyed
# by namespace ID and cannot exist without its namespace.
################################################################################

variable "search_attributes" {
  description = "Custom search attributes, as a map of name => type. Valid types are `bool`, `datetime`, `double`, `int`, `keyword`, `keyword_list` and `text`, matched case-insensitively. Search attributes cannot be deleted once created, so removing an entry will not remove it from the namespace"
  type        = map(string)
  default     = {}

  # Note `keyword_list`, with an underscore. Types are matched case-insensitively,
  # so `KeywordList` resolves to `keywordlist` and is rejected by the API — this
  # check surfaces that during plan instead.
  validation {
    condition = alltrue([
      for type in values(var.search_attributes) :
      contains(["bool", "datetime", "double", "int", "keyword", "keyword_list", "text"], lower(type))
    ])
    error_message = "Search attribute types must be one of: bool, datetime, double, int, keyword, keyword_list, text (case-insensitive). Note `keyword_list`, not `KeywordList`."
  }
}

################################################################################
# Tags
#
# Managed here for the same reason as search attributes. The provider owns the
# namespace's complete tag set, so this is a single resource rather than one per
# tag.
################################################################################

variable "tags" {
  description = "Tags to apply to the namespace. Keys must be lowercase. This replaces the namespace's entire tag set, so tags added outside Terraform are removed on the next apply"
  type        = map(string)
  default     = {}
}
