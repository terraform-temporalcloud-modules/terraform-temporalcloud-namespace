# Reports test namespaces still present in the account.
#
# Creates nothing: a data source and an output only. `terraform test` destroys
# what it creates, but a cancelled or crashed run can leave a namespace behind,
# and nothing else would notice.
#
# Run after the apply tests. Anything reported here is a leftover.

data "temporalcloud_namespaces" "all" {}

locals {
  # The data source returns null, not an empty list, when the account holds no
  # namespaces. Iterating that raises "Iteration over null value" and fails the
  # check on exactly the accounts with nothing to report, so coalesce first.
  orphans = [
    for n in coalesce(data.temporalcloud_namespaces.all.namespaces, []) : n.name
    if startswith(n.name, var.test_namespace_prefix)
  ]
}
