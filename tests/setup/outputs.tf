output "namespace_name" {
  description = "Unique namespace name for this test run, prefixed `yulei-tftest-ns-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account"
  # `yulei-` identifies the owner, `tftest-` distinguishes test namespaces from
  # anything created by hand.
  #
  # The random part is truncated because the API caps namespace names at 39
  # characters — well short of the 64 the provider's schema declares, and it
  # rejects longer names at apply with `namespace cannot exceed 39 characters`.
  # The 16-character prefix plus the longest suffix a test appends (`-payments`,
  # 9) leaves 14; 12 keeps a margin. An untruncated `random_pet` is unbounded and
  # overran the limit on a long draw.
  #
  # trimsuffix covers the cut landing on the pet's `-` separator, which would
  # leave a trailing hyphen and fail the provider's name validation.
  value = "yulei-tftest-ns-${trimsuffix(substr(random_pet.this.id, 0, 12), "-")}"
}

output "region" {
  description = "A region this account is entitled to use, for single-region test namespaces"
  value       = local.region_ids[0]
}

output "ha_regions" {
  description = "Two entitled regions from the same cloud provider, suitable for a high availability namespace. Empty when no single provider offers the account two regions"
  value = length(local.ha_candidates) > 0 ? slice(
    sort(local.regions_by_provider[local.ha_candidates[0]]), 0, 2
  ) : []
}

output "available_regions" {
  description = "Every region this account may use. Surfaced so a test run documents the account's actual entitlements, which differ from the published region list"
  value       = local.region_ids
}

output "ca_certificate_pem" {
  description = "Self-signed CA certificate for the mTLS test, in PEM format. The module expects it Base64-encoded"
  value       = tls_self_signed_cert.ca.cert_pem
}
