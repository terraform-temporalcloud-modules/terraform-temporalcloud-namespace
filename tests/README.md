# Tests

Two layers with different costs and different coverage. They are not
interchangeable.

| Path | Runs on | Needs credentials | Proves |
| --- | --- | --- | --- |
| `local/` | every PR | no | Every input passed and every output referenced; the variable surface has not changed incompatibly |
| `*.tftest.hcl` | on demand + weekly | **yes** | Temporal Cloud actually accepts these payloads |
| `setup/` | helper for `*.tftest.hcl` | no | — |

## `local/` — validation gate

Sources the module by relative path and passes **every** input, referencing every
output. `terraform validate` fails here the moment the variable surface changes.

The `examples/` are also checked against the working tree — `scripts/validate-examples.sh`
rewrites their registry source in a temp copy — but they exercise only a realistic
subset of inputs, so this directory remains the exhaustive one. See
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

Without the key, the provider fails at configure time and every run block is
skipped — including `setup`, which reads the `temporalcloud_regions` data source.
A clean parse therefore looks like:

```
Failure! 0 passed, 0 failed, 4 skipped.
```

Useful for checking syntax without billing anything. A syntax or reference error
looks different: it names the file and line rather than reporting a connection
failure.

### Cost and cleanup

These create real, billable namespaces. `terraform test` destroys what it created,
including after a failed assertion, but a cancelled or crashed runner can orphan
one.

Every namespace these tests can create is prefixed **`yulei-`** so leftovers are
identifiable and safe to delete:

| Prefix | Created by |
| --- | --- |
| `yulei-tftest-<random>` | `*.tftest.hcl` — the apply tests |
| `yulei-tflocal-*` | `local/` — only if someone runs `terraform apply` there by hand; CI never applies it |

To find leftovers:

```bash
# Cloud UI, or:
terraform state list          # inside the failed directory, if state survived
```

Anything matching `yulei-*` that no live configuration owns is an orphan and can be
deleted.

Note the `examples/` directories are **not** covered by this prefix — they create
`ex-complete` and `ex-mtls`. That is deliberate: example code is published to the
Terraform Registry and read by customers, so it must not carry a personal prefix.
Check for those two names separately if you have applied an example by hand.

Point all of this at a scratch account, never production.

### CI

`.github/workflows/test.yml` — `workflow_dispatch` plus a Monday canary.
Deliberately not on `pull_request`: forks cannot read secrets, applies cost money,
and creation is slow. Runs are serialized with `cancel-in-progress: false`, because
cancelling mid-apply would abandon a namespace with no destroy.

Requires the `TEMPORAL_CLOUD_API_KEY` repository secret.
