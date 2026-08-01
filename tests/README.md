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
cover the module input surface, with two exceptions noted below:

| File | Covers |
| --- | --- |
| `namespace.tftest.hcl` | Create with API key auth, capacity, codec server, fairness and timeouts; then update in place to add all seven search attribute types and tags |
| `mtls.tftest.hcl` | `accepted_client_ca` and `certificate_filters`, asserting an mTLS endpoint comes back |
| `delete_protection.tftest.hcl` | `namespace_lifecycle`, enabling then disabling protection |
| `wrappers.tftest.hcl` | The `wrappers` submodule: two namespaces from one call, with per-item overrides |
| `disabled.tftest.hcl` | `create_namespace = false` creates nothing and every output falls back |

Fixtures: `setup/` generates a unique name, selects a region the account is
entitled to, and issues a throwaway CA for the mTLS test. `orphan-check/` reports leftovers and creates
nothing.

Two inputs are not covered on apply.

`connectivity_rule_ids` is covered only by `local/`. Applying it
needs a `temporalcloud_connectivity_rule`, and creating one fails on an account
that has reached its public connectivity rule limit. The provider offers no data
source to enumerate existing rules, so there is no way to borrow one. The resource
also belongs to a different module in this family.

The two-region high availability variant of `regions` is also apply-covered only by
`local/`. Temporal Cloud permits only certain region combinations, rejecting others
with `Selected regions <a> and <b> are disallowed` — and same-provider pairs are
not automatically valid. An account whose entitled regions contain no permitted
pair cannot exercise it. Single-region `regions` is covered.

Files run sequentially and each is torn down before the next begins, so only
`wrappers.tftest.hcl` has more than one namespace alive at a time.

[CONTRIBUTING.md](../CONTRIBUTING.md) explains why the layers are split this way
and which API behaviours they guard against.

## What the apply tests cannot assert

Three things the suite applies but cannot check through any output. They are
recorded here so nobody adds an assertion that looks like proof and is not.

**The endpoints do not reveal the auth mode.** Temporal Cloud populates all three
— `grpc_address`, `mtls_grpc_address` and `web_address` — on *every* namespace,
whichever authentication is configured. A namespace created with
`api_key_auth = true` and no CA still reports an mTLS address, and a
certificate-only namespace still reports a gRPC address. So
`namespace_mtls_grpc_address != ""` does **not** prove `accepted_client_ca` took
effect, and `namespace_grpc_address != ""` does not prove `api_key_auth` did. The
tests assert instead that each per-namespace address is scoped to the namespace
under test. Note that the gRPC address is a shared *regional* endpoint, identical
for every namespace in that region — only the mTLS and Web addresses are
per-namespace hosts.

What `mtls.tftest.hcl` genuinely proves is that the API **accepts** a
Base64-encoded CA bundle and a `certificate_filters` list in the shape the module
builds; a wrong encoding or a mis-nested filter fails the apply. The module echoes
neither input back as an output, so there is nothing further to assert.

**In-place update versus replacement is not fully provable.** A namespace ID is
`<name>.<account_id>`, derived rather than opaque, so a replacement that reused the
name would report the same ID. `namespace.tftest.hcl` asserts identity *continuity*
across the update — comparing against the prior run block's ID, never against a
name the same block passed in as a variable, which would hold either way.

**`retention_days` is not observable.** The module exposes no retention output, so
the per-item override in `wrappers.tftest.hcl` is applied but unasserted.

## Account access the apply tests require

Only `TEMPORAL_CLOUD_API_KEY` — no AWS, GCP, mail domain or other external
credential. The key must belong to an account that can create and delete
namespaces, and the account needs these entitlements or the suite fails for
reasons unrelated to the module:

| Requirement | Used by | If absent |
| --- | --- | --- |
| At least one entitled region | every file | `check-api.sh` fails first, by design |
| Headroom for 2 concurrent namespaces | `wrappers.tftest.hcl` | namespace quota error |
| `capacity` mode `on_demand` | `namespace.tftest.hcl` | the API rejects the capacity block |
| Task queue fairness | `namespace.tftest.hcl` | the API rejects `fairness` |
| Delete protection | `delete_protection.tftest.hcl` | the API rejects `namespace_lifecycle` |

Region entitlements are per account and are **not** the published region list, so
the suite reads `data.temporalcloud_regions` rather than hardcoding one. A public
connectivity rule quota would also be needed to apply `connectivity_rule_ids`,
which is why that input is not apply-covered.

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
Failure! 0 passed, 0 failed, 11 skipped.
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
| `yulei-tftest-ns-<random>` | `*.tftest.hcl` |
| `yulei-tflocal-*` | `local/`, only if applied by hand — CI never applies it |

Anything matching those prefixes that no live configuration owns can be deleted.

The `examples/` directories are not covered by this prefix; they create
`ex-complete` and `ex-mtls`. Example code is published to the Terraform Registry,
so it carries no test-specific naming. Check for those two separately if you have
applied an example by hand.
