output "namespace_name" {
  description = "Unique namespace name for this test run, prefixed `yulei-tftest-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account"
  # `yulei-` identifies the owner, `tftest-` distinguishes test namespaces from
  # anything created by hand. Satisfies the provider's constraint: 2-64 chars,
  # starts with a letter, lowercase alphanumerics and hyphens, no trailing hyphen.
  value = "yulei-tftest-${random_pet.this.id}"
}
