locals {
  create_namespace = var.create_namespace
}

################################################################################
# Namespace
#
# `capacity`, `certificate_filters`, `codec_server`, `fairness` and
# `namespace_lifecycle` are nested attributes in the provider schema rather than
# blocks, so they are assigned straight from their variables and a null value
# omits them. `timeouts` is the only true block, hence the dynamic block below.
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
# One resource per attribute, keyed by name, so adding or removing an attribute
# does not disturb the state addresses of the others.
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
# A single resource owns the namespace's whole tag set, so this takes `count`
# rather than `for_each` over individual tags.
################################################################################

resource "temporalcloud_namespace_tags" "this" {
  count = local.create_namespace && length(var.tags) > 0 ? 1 : 0

  namespace_id = temporalcloud_namespace.this[0].id
  tags         = var.tags
}
