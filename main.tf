locals {
  create_namespace = var.create_namespace
}

################################################################################
# Namespace
#
# `capacity`, `certificate_filters`, `codec_server`, `fairness` and
# `namespace_lifecycle` are nested *attributes* in the provider schema, not
# blocks, so they are assigned directly from their variables. Passing null omits
# them, which is what the provider expects for "not configured". Only `timeouts`
# is a real block and therefore needs a dynamic block.
################################################################################

resource "temporalcloud_namespace" "this" {
  count = local.create_namespace ? 1 : 0

  name           = var.name
  regions        = var.regions
  retention_days = var.retention_days

  api_key_auth        = var.api_key_auth
  accepted_client_ca  = var.accepted_client_ca
  certificate_filters = var.certificate_filters

  capacity              = var.capacity
  codec_server          = var.codec_server
  fairness              = var.fairness
  namespace_lifecycle   = var.namespace_lifecycle
  connectivity_rule_ids = var.connectivity_rule_ids

  dynamic "timeouts" {
    for_each = length([for v in var.timeouts : v if v != null]) > 0 ? [var.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

################################################################################
# Search attributes
#
# One resource per attribute, so `for_each` keyed on the attribute name keeps
# state addresses stable when attributes are added or removed.
################################################################################

resource "temporalcloud_namespace_search_attribute" "this" {
  for_each = local.create_namespace ? var.search_attributes : {}

  namespace_id = temporalcloud_namespace.this[0].id
  name         = each.key
  type         = each.value
}

################################################################################
# Tags
#
# Singleton: the provider manages the complete tag set for the namespace, so this
# takes `count` rather than `for_each`.
################################################################################

resource "temporalcloud_namespace_tags" "this" {
  count = local.create_namespace && length(var.tags) > 0 ? 1 : 0

  namespace_id = temporalcloud_namespace.this[0].id
  tags         = var.tags
}
