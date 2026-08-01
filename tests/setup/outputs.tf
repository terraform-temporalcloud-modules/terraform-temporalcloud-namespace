output "namespace_name" {
  description = "Unique namespace name for this test run, prefixed `yulei-tftest-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account"
  # `yulei-` identifies the owner, `tftest-` distinguishes test namespaces from
  # anything created by hand. Satisfies the provider's constraint: 2-64 chars,
  # starts with a letter, lowercase alphanumerics and hyphens, no trailing hyphen.
  value = "yulei-tftest-${random_pet.this.id}"
}

output "region" {
  description = "A region this account is entitled to use, for single-region test namespaces"
  value       = local.region_ids[0]
}

output "ha_regions" {
  description = "Two entitled regions for a high availability namespace, or an empty list when the account has fewer than two"
  value       = length(local.region_ids) >= 2 ? slice(local.region_ids, 0, 2) : []
}

output "available_regions" {
  description = "Every region this account may use. Surfaced so a test run documents the account's actual entitlements, which differ from the published region list"
  value       = local.region_ids
}
