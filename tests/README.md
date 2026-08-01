# Tests

Two layers with different costs and different coverage. They are not
interchangeable.

| Path | Runs on | Needs credentials | Proves |
| --- | --- | --- | --- |
| `local/` | every PR | no | The configuration type-checks and the variable surface has not changed incompatibly |
| `*.tftest.hcl` | on demand + weekly | **yes** | Temporal Cloud actually accepts these payloads |
| `setup/` | helper for `*.tftest.hcl` | no | — |

## `local/` — validation gate

Sources the module by relative path and passes every input. `terraform validate`
fails here the moment the variable surface changes, which the `examples/` cannot
catch because they resolve the last published release. See
[local/README.md](local/README.md).

This is a **validation** gate, not a test: `terraform validate` never executes
anything and never contacts the API.

## `*.tftest.hcl` — apply tests

Native `terraform test`, `command = apply` by default, against a real account.
This is the only layer that can catch the API rejecting a valid-looking
configuration — a region string the account cannot use, a `capacity` mode it is
not entitled to, a search attribute type the API refuses.

| File | What it covers |
| --- | --- |
| `namespace.tftest.hcl` | Creates one namespace, asserts ID format / endpoints / regions, then **updates it in place** to add all 7 search attribute types and tags, asserting they round-trip through the API |
| `disabled.tftest.hcl` | `create_namespace = false` creates nothing and every output falls back via `try()` rather than erroring |

One namespace is created, not one per case. Creation is slow and accounts cap how
many namespaces can exist, so later `run` blocks update the same namespace —
which also exercises the folded-in child resources attaching to an existing
parent.

### Running locally

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Without the key, the provider fails at configure time and every run block that
touches Temporal Cloud is skipped. `run "setup"` still passes, so a clean parse
looks like `1 passed, 0 failed, 3 skipped` — useful for checking syntax without
billing anything.

### Cost and cleanup

These create real, billable namespaces. `terraform test` destroys what it created,
including after a failed assertion, but a cancelled or crashed runner can orphan
one. Names are prefixed `tftest-` so leftovers are easy to find:

```bash
terraform console <<< 'data.temporalcloud_namespaces.all'   # or check the Cloud UI
```

Point these at a scratch account, never production.

### CI

`.github/workflows/test.yml` — `workflow_dispatch` plus a Monday canary.
Deliberately not on `pull_request`: forks cannot read secrets, applies cost money,
and creation is slow. Runs are serialized with `cancel-in-progress: false`, because
cancelling mid-apply would abandon a namespace with no destroy.

Requires the `TEMPORAL_CLOUD_API_KEY` repository secret.
