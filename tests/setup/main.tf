# Generates a unique namespace name per test run.
#
# Temporal Cloud namespace names are unique within an account, so a fixed name
# would make a second run — or a concurrent one — fail on a name already in use,
# and would collide with any namespace a human left behind after a failed run.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}

# The regions this account is actually entitled to.
#
# Do NOT hardcode a region here. `aws-us-east-1` is listed on
# https://docs.temporal.io/cloud/regions yet this account rejected it with
# "Region ... is not a valid Temporal Cloud region", so entitlements vary per
# account and the provider's error wording is misleading. Reading the data source
# is what the provider itself recommends, and it keeps the tests portable across
# accounts.
data "temporalcloud_regions" "available" {}

locals {
  # Sorted so repeat runs pick the same region and results stay comparable.
  region_ids = sort([for r in data.temporalcloud_regions.available.regions : r.id])
}
