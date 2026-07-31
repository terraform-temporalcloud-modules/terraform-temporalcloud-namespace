module "wrapper" {
  source = "../"

  for_each = var.items

  accepted_client_ca    = try(each.value.accepted_client_ca, var.defaults.accepted_client_ca, null)
  api_key_auth          = try(each.value.api_key_auth, var.defaults.api_key_auth, null)
  capacity              = try(each.value.capacity, var.defaults.capacity, null)
  certificate_filters   = try(each.value.certificate_filters, var.defaults.certificate_filters, null)
  codec_server          = try(each.value.codec_server, var.defaults.codec_server, null)
  connectivity_rule_ids = try(each.value.connectivity_rule_ids, var.defaults.connectivity_rule_ids, null)
  create_namespace      = try(each.value.create_namespace, var.defaults.create_namespace, true)
  fairness              = try(each.value.fairness, var.defaults.fairness, null)
  name                  = try(each.value.name, var.defaults.name, "")
  namespace_lifecycle   = try(each.value.namespace_lifecycle, var.defaults.namespace_lifecycle, null)
  regions               = try(each.value.regions, var.defaults.regions, [])
  retention_days        = try(each.value.retention_days, var.defaults.retention_days, 30)
  search_attributes     = try(each.value.search_attributes, var.defaults.search_attributes, {})
  tags                  = try(each.value.tags, var.defaults.tags, {})
  timeouts              = try(each.value.timeouts, var.defaults.timeouts, {})
}
