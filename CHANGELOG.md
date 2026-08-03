# Changelog

All notable changes to this project will be documented in this file.

## [2.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v2.0.1...v2.0.2) (2026-08-03)

### Tests

* Coalesce null data source lists in the orphan check ([#11](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/11)) ([f5ef240](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/f5ef240899d5f1de90266969843fb2d23578fc4d))

## [2.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v2.0.0...v2.0.1) (2026-08-01)

### Bug Fixes

* Cap the namespace name at 39 characters, and pin examples to v2 ([2ea196d](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/2ea196d0f951c5593c4164825a2579197279087e))

## [2.0.0](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.5...v2.0.0) (2026-08-01)

### ⚠ BREAKING CHANGES

* name and regions no longer have defaults. A module call that
sets create_namespace = false must now pass them explicitly, for example
name = "" and regions = [].

### Features

* Require the inputs the provider requires ([7abab4c](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/7abab4c3e5fe1f34cfdf6f51de5d32edd86ba08d))

### Tests

* Keep generated namespace names within the API limit ([f992cbd](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/f992cbd616e09fab8cafabcfd6a89087920dd16d))

## [1.1.5](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.4...v1.1.5) (2026-08-01)

### Documentation

* Drop the badge explanation from the README ([b4ed5e5](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/b4ed5e580f5aa988d977e21f35ce968fa4d2c9bf))
* Trim the validate explanation to what a consumer needs ([1e99a51](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/1e99a511761ac311a36ab55c5ed1d64c70141d72))

## [1.1.4](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.3...v1.1.4) (2026-08-01)

## [1.1.3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.2...v1.1.3) (2026-08-01)

### Bug Fixes

* Correct HA region documentation and complete apply test coverage ([#8](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/8)) ([be53124](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/be531247ad293883358100ec4d231be40a092e8e))

## [1.1.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.1...v1.1.2) (2026-08-01)

### Bug Fixes

* Apply-test the module, fix four real API bugs, drop the two-PR dance ([#6](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/6)) ([339a42f](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/339a42febb146dc1d4e10bdd8387f31972646091))

## [1.1.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.1.0...v1.1.1) (2026-08-01)

### Bug Fixes

* Prefix test namespaces with yulei- for cleanup ([#5](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/5)) ([2b2c6b2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/2b2c6b271de8f3d75f59033b296839264aec34ab))

## [1.1.0](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.0.3...v1.1.0) (2026-08-01)

### Features

* Add apply-based terraform test suite ([#4](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/4)) ([fae789b](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/fae789bfb39530f599230dc84a713d5d39f86130))

## [1.0.3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.0.2...v1.0.3) (2026-08-01)

### Bug Fixes

* Point examples at the published module, add tests/local ([#3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/3)) ([8b2085c](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/8b2085c341314d6a029edbb6be3fd77a5ea44fbd))

## [1.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.0.1...v1.0.2) (2026-07-31)

### Bug Fixes

* Hold changelog preset at 9.x for semantic-release compatibility ([#2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/issues/2)) ([a53d3e3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/a53d3e3f7ac36a5073cfa7b6274e54c2d19a032c))

## [1.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/compare/v1.0.0...v1.0.1) (2026-07-31)

## 1.0.0 (2026-07-31)

### Features

* Add Temporal Cloud namespace module ([8d92d7e](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-namespace/commit/8d92d7eb97ddc7817891aef722f0a0f17675038d))
