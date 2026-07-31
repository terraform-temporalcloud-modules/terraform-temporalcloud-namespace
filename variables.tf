variable "create_namespace" {
  description = "Controls if the namespace should be created"
  type        = bool
  default     = true
}

################################################################################
# Namespace
################################################################################

variable "name" {
  description = "The name of the namespace. Must be 2-64 characters, start with a letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen"
  type        = string
  default     = ""

  validation {
    # Mirrors the provider's own constraint so a typo fails at plan time rather
    # than after a round trip to the Temporal Cloud API.
    condition     = var.name == "" || can(regex("^[a-z][a-z0-9-]{0,62}[a-z0-9]$", var.name))
    error_message = "The namespace name must be 2-64 characters, start with a letter, contain only lowercase letters, numbers and hyphens, and not end with a hyphen."
  }
}

variable "regions" {
  description = "The list of regions where this namespace is available. Must be one or two regions, prefixed with the cloud provider (e.g. `aws-us-east-1`, not `us-east-1`). Two regions provisions a high availability (HA) namespace replicated across them"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.regions) <= 2
    error_message = "A namespace supports at most two regions. Two regions creates an HA namespace."
  }
}

variable "retention_days" {
  description = "The number of days to retain workflow history. Changes apply to all new running workflows"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 1
    error_message = "The retention period must be at least 1 day."
  }
}

################################################################################
# Authentication
################################################################################

variable "api_key_auth" {
  description = "If true, Temporal Cloud will enable API key authentication for this namespace"
  type        = bool
  default     = null
}

variable "accepted_client_ca" {
  description = "The Base64-encoded CA cert in PEM format that clients use when authenticating with Temporal Cloud. Required when the namespace uses mTLS authentication"
  type        = string
  default     = null
}

variable "certificate_filters" {
  description = "A list of filters to apply to client certificates. If present, connections are only allowed from client certificates whose distinguished name properties match at least one filter. Omit rather than passing an empty list"
  type = list(object({
    common_name              = optional(string)
    organization             = optional(string)
    organizational_unit      = optional(string)
    subject_alternative_name = optional(string)
  }))
  default = null

  validation {
    condition     = var.certificate_filters == null || length(coalesce(var.certificate_filters, [])) > 0
    error_message = "Empty certificate filter lists are not allowed by the provider. Omit the variable instead."
  }
}

################################################################################
# Namespace configuration
################################################################################

variable "capacity" {
  description = "The capacity configuration for the namespace. `mode` must be one of `provisioned` or `on_demand`; `value` is required when mode is `provisioned`"
  type = object({
    mode  = optional(string)
    value = optional(number)
  })
  default = null

  validation {
    condition     = try(var.capacity.mode, null) == null || contains(["provisioned", "on_demand"], coalesce(try(var.capacity.mode, null), "on_demand"))
    error_message = "Capacity mode must be one of: provisioned, on_demand."
  }

  validation {
    condition     = try(var.capacity.mode, null) != "provisioned" || try(var.capacity.value, null) != null
    error_message = "Capacity value must be set when capacity mode is 'provisioned'."
  }
}

variable "codec_server" {
  description = "A codec server used by the Temporal Cloud UI to decode payloads for all users interacting with this namespace, even when the workflow history itself is encrypted"
  type = object({
    endpoint                         = string
    custom_error_link                = optional(string)
    custom_error_message             = optional(string)
    include_cross_origin_credentials = optional(bool)
    pass_access_token                = optional(bool)
  })
  default = null

  validation {
    condition     = var.codec_server == null || startswith(coalesce(try(var.codec_server.endpoint, null), "https"), "https")
    error_message = "The codec server endpoint must begin with \"https\"."
  }
}

variable "fairness" {
  description = "The fairness configuration for the namespace. Task queue fairness defaults to disabled"
  type = object({
    task_queue_fairness_enabled = optional(bool)
  })
  default = null
}

variable "namespace_lifecycle" {
  description = "Temporal Cloud lifecycle configuration, such as delete protection. Unrelated to the Terraform `lifecycle` meta-argument"
  type = object({
    enable_delete_protection = optional(bool)
  })
  default = null
}

variable "connectivity_rule_ids" {
  description = "The IDs of the connectivity rules to attach to this namespace"
  type        = set(string)
  default     = null
}

variable "timeouts" {
  description = "Create and delete timeouts for the namespace, as duration strings (e.g. `30s`, `2h45m`)"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}

################################################################################
# Search attributes
#
# Folded into this module rather than published separately: the resource is keyed
# by namespace_id and is meaningless without its parent namespace.
################################################################################

variable "search_attributes" {
  description = "Map of custom search attribute name => type. Valid types: Bool, Datetime, Double, Int, Keyword, KeywordList, Text"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for type in values(var.search_attributes) :
      contains(["Bool", "Datetime", "Double", "Int", "Keyword", "KeywordList", "Text"], type)
    ])
    error_message = "Search attribute types must be one of: Bool, Datetime, Double, Int, Keyword, KeywordList, Text."
  }
}

################################################################################
# Tags
#
# Folded in for the same reason as search attributes. Note the provider manages
# the *complete* tag set for a namespace, so this is a singleton resource.
################################################################################

variable "tags" {
  description = "Map of tags to apply to the namespace. The provider manages the complete tag set, so tags applied outside Terraform will be removed"
  type        = map(string)
  default     = {}
}
