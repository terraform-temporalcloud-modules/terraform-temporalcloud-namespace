# Generates a unique namespace name per test run.
#
# Temporal Cloud namespace names are unique within an account, so a fixed name
# would make a second run — or a concurrent one — fail on a name already in use,
# and would collide with any namespace a human left behind after a failed run.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}
