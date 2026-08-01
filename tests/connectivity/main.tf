# A public connectivity rule, so `connectivity_rule_ids` can be exercised.
#
# The rule itself belongs to a different module in this family; it is created here
# only as a fixture. `public` needs no cloud-side setup, unlike `private`, which
# would require a real VPC endpoint.
resource "temporalcloud_connectivity_rule" "this" {
  connectivity_type = "public"
}
