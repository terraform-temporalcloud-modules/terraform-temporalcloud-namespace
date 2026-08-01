output "namespace_name" {
  description = "Unique namespace name for this test run. Satisfies the provider's constraint: 2-64 chars, starts with a letter, lowercase alphanumerics and hyphens, no trailing hyphen"
  value       = "tftest-${random_pet.this.id}"
}
