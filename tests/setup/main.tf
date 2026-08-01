# Generates a unique namespace name per test run.
#
# Temporal Cloud namespace names are unique within an account, so a fixed name
# would make a second run — or a concurrent one — fail on a name already in use,
# and would collide with any namespace a human left behind after a failed run.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}

# Regions this account is entitled to use.
#
# Not hardcoded: the regions an account may use are a subset of the published
# list, so a fixed ID makes the suite account-specific and can fail with
# "is not a valid Temporal Cloud region".
data "temporalcloud_regions" "available" {}

locals {
  # Sorted so repeat runs pick the same region and results stay comparable.
  region_ids = sort([for r in data.temporalcloud_regions.available.regions : r.id])
}
