# Tests

Not usage examples — see [examples/](../examples) for those.

| Path | Runs on | Credentials |
| --- | --- | --- |
| `local/` | every pull request | no |
| `*.tftest.hcl` | on demand, weekly | **yes** |
| `setup/` | helper for `*.tftest.hcl` | no |

`local/` passes every module input and references every output, so `terraform
validate` fails there as soon as the variable surface changes.

`*.tftest.hcl` applies against a real Temporal Cloud account, which is the only
way to catch the API rejecting a configuration that type-checks. `setup/`
generates a unique namespace name and selects a region the account is entitled
to.

[CONTRIBUTING.md](../CONTRIBUTING.md) explains why the layers are split this way
and which API behaviours they guard against.

## Running the apply tests

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Point them at a scratch account: they create and destroy **real, billable**
namespaces.

Without a key, every run block is skipped — a cheap way to confirm the test files
parse:

```text
Failure! 0 passed, 0 failed, 4 skipped.
```

## Cleaning up leftovers

`terraform test` destroys what it created, including after a failed assertion, but
a cancelled or crashed run can orphan a namespace. Test namespaces are prefixed so
they are identifiable:

| Prefix | Created by |
| --- | --- |
| `yulei-tftest-<random>` | `*.tftest.hcl` |
| `yulei-tflocal-*` | `local/`, only if applied by hand — CI never applies it |

Anything matching those prefixes that no live configuration owns can be deleted.

The `examples/` directories are not covered by this prefix; they create
`ex-complete` and `ex-mtls`. Example code is published to the Terraform Registry,
so it carries no test-specific naming. Check for those two separately if you have
applied an example by hand.
