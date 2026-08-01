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
way to catch the API rejecting a configuration that type-checks. Between them they
cover every module input:

| File | Covers |
| --- | --- |
| `namespace.tftest.hcl` | Create with API key auth, capacity, codec server, fairness, timeouts and a connectivity rule; then update in place to add all seven search attribute types and tags |
| `mtls.tftest.hcl` | `accepted_client_ca` and `certificate_filters`, asserting an mTLS endpoint comes back |
| `ha.tftest.hcl` | Two regions, replicated |
| `delete_protection.tftest.hcl` | `namespace_lifecycle`, enabling then disabling protection |
| `wrappers.tftest.hcl` | The `wrappers` submodule: two namespaces from one call, with per-item overrides |
| `disabled.tftest.hcl` | `create_namespace = false` creates nothing and every output falls back |

Fixtures: `setup/` generates a unique name, selects a region the account is
entitled to, and issues a throwaway CA for the mTLS test. `connectivity/` creates
a public connectivity rule. `orphan-check/` reports leftovers and creates nothing.

Files run sequentially and each is torn down before the next begins, so only
`wrappers.tftest.hcl` has more than one namespace alive at a time.

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
a cancelled or crashed run can orphan a namespace. The CI workflow therefore runs
`scripts/check-orphans.sh` afterwards — always, including when the tests fail,
since that is when something is most likely to be left behind. It fails the job and
names anything still present. Run it by hand the same way:

```bash
scripts/check-orphans.sh
```

Test namespaces are prefixed so they are identifiable:

| Prefix | Created by |
| --- | --- |
| `yulei-tftest-<random>` | `*.tftest.hcl` |
| `yulei-tflocal-*` | `local/`, only if applied by hand — CI never applies it |

Anything matching those prefixes that no live configuration owns can be deleted.

The `examples/` directories are not covered by this prefix; they create
`ex-complete` and `ex-mtls`. Example code is published to the Terraform Registry,
so it carries no test-specific naming. Check for those two separately if you have
applied an example by hand.
