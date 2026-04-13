# Testing Guidelines

## Running Tests

```bash
# All submodule unit tests (CI runs this on every PR)
make unit-tests

# Single submodule (run from the module root, NOT from tests/)
cd modules/<name> && terraform init -backend=false -input=false && terraform test

# Lint (also runs in CI before tests)
make lint
```

CI workflow (`.github/workflows/test.yml`) runs `make lint` then `make unit-tests` on every pull request. No credentials are needed -- all tests use mock providers.

## File Layout

Tests live in `modules/<name>/tests/<name>.tftest.hcl`. Each submodule that has testable logic gets exactly one test file in a `tests/` subdirectory. The test file is run from the module root (parent of `tests/`), not from `tests/` itself.

```
modules/
  log-forwarder/
    main.tf
    variables.tf
    versions.tf
    tests/
      log_forwarder.tftest.hcl    # snake_case
```

Test file names use snake_case. Most test files match the module name pattern (e.g., `log_forwarder.tftest.hcl` for `log-forwarder`), though some use descriptive names focused on what is being tested (e.g., `aws_node_pool.tftest.hcl` for `machine-pool`).

Modules with tests today: `idp`, `log-forwarder`, `machine-pool`, `oidc-config-and-provider`, `rosa-cluster-hcp`. Modules without tests: `account-iam-resources`, `additional-cp-sg`, `bastion-host`, `image-mirrors`, `kubelet-configs`, `operator-roles`, `shared-vpc-resources`, `vpc`.

## Mock Provider Pattern

Every `.tftest.hcl` file declares mock providers at the top, before any `variables` or `run` blocks. Every provider the module's `versions.tf` requires must be mocked. No real credentials are used.

**Minimal mock (most common):** Sufficient for plan-only validation and `expect_failures` tests.

```hcl
mock_provider "rhcs" {
  alias = "default"
}
```

**Mock with data defaults:** Required when the module reads data sources at plan time (e.g., `aws_partition`, `aws_subnet`).

```hcl
mock_provider "aws" {
  alias = "default"
  mock_data "aws_partition" {
    defaults = {
      dns_suffix = "amazonaws.com"
      id         = "aws"
      partition  = "aws"
    }
  }
}
```

**Mock with resource defaults and `override_during`:** Used when a test needs computed resource attributes during plan (attributes that would normally be unknown until apply).

```hcl
mock_provider "rhcs" {
  alias           = "with_override"
  override_during = plan
  mock_resource "rhcs_hcp_machine_pool" {
    defaults = {
      aws_node_pool = {
        capacity_reservation_preference = "defined_by_provider"
      }
    }
  }
}
```

**Multiple aliases for the same provider** are used when different run blocks need different mock behaviors (e.g., one with `override_during = plan` and one without).

**Mock all required providers.** If `versions.tf` declares `aws`, `rhcs`, `time`, and `null`, mock all four. See `oidc_config.tftest.hcl` for a four-provider example.

## Run Block Structure

Every `run` block specifies `command = plan` (or occasionally `command = apply` for lifecycle tests). The `providers` map must wire each provider to a mock alias.

```hcl
run "descriptive_snake_case_name" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    # only override what this specific test needs
  }

  assert {
    condition     = <expression>
    error_message = "Human-readable failure description."
  }
}
```

**Conventions:**
- Run block names use `snake_case` and describe the scenario (e.g., `both_s3_and_cloudwatch_fails`, `valid_htpasswd_plan`).
- Negative-path names end with `_fails`.
- Positive-path names include `_plan` or describe the expected outcome.
- Use shared `variables {}` at file level for common defaults; override per-run block only what changes.
- `command = apply` is used only when testing lifecycle behavior (e.g., `ignore_changes`). Pair with `state_key` to isolate state between apply/plan sequences.

## Assertion Patterns

**Positive assertions** -- verify a planned value is correct:

```hcl
assert {
  condition     = rhcs_log_forwarder.this.cluster == "fake-cluster-123"
  error_message = "Expected cluster id to be passed through."
}
```

**Count/length assertions** -- verify conditional resource creation:

```hcl
assert {
  condition     = length(rhcs_hcp_default_ingress.default_ingress) == 1
  error_message = "Must have count 1 when var.wait_for_create_complete is true."
}
```

**Null checks:**

```hcl
assert {
  condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.capacity_reservation_id == null
  error_message = "Expected capacity_reservation_id to be null."
}
```

**Variable input assertions** (verify validation accepted an input without erroring):

```hcl
assert {
  condition     = var.aws_node_pool.capacity_reservation_preference == null
  error_message = "Expected explicit null accepted by validation."
}
```

## expect_failures Pattern

Use `expect_failures` to test that invalid inputs are rejected by variable `validation` blocks or `lifecycle` preconditions. The target is the variable or resource that contains the failing validation.

**Variable validation failure:**

```hcl
run "oidc_prefix_too_long_fails" {
  command = plan
  providers = { rhcs = rhcs.default; aws = aws.default; time = time.default; null = null.default }
  variables { managed = true; oidc_prefix = "abcdefghijklmnopq" }
  expect_failures = [var.oidc_prefix]
}
```

**Resource precondition failure:**

```hcl
run "github_missing_client_id_fails" {
  command = plan
  providers = { rhcs = rhcs.default }
  variables {
    cluster_id           = "fake-cluster-123"
    name                 = "test-github"
    idp_type             = "github"
    github_idp_client_id = null
    github_idp_client_secret = "not-empty-secret"
  }
  expect_failures = [rhcs_identity_provider.github_identity_provider]
}
```

Target the specific variable (`var.x`) for validation blocks, or the specific resource (`resource_type.name`) for lifecycle preconditions. Do not use generic references.

## Boolean Branch Coverage

When module logic branches on a boolean variable (e.g., `count = var.x ? 1 : 0`), write separate run blocks for both `true` and `false`. This is an explicit repo policy from `AGENTS.md`.

```hcl
# rosa_cluster_hcp.tftest.hcl demonstrates this pattern:
run "plan_default_ingress_count_when_wait_for_create_complete_true" {
  # default is true -- asserts count == 1
}
run "plan_default_ingress_count_when_wait_for_create_complete_false" {
  variables { wait_for_create_complete = false }
  # asserts count == 0
}
```

## Boundary and Edge Case Testing

Test edge cases for validation rules. The `log_forwarder` tests demonstrate comprehensive coverage:
- Mutually exclusive inputs: both set, neither set
- Empty lists, null lists, empty strings, whitespace-only strings
- Valid happy path for each accepted configuration

## Adding Tests to a New or Existing Module

1. Create `modules/<name>/tests/<name>.tftest.hcl` if it does not exist.
2. Mock every provider declared in the module's `versions.tf`.
3. Add `expect_failures` runs for each `validation` block and `lifecycle` precondition.
4. Add positive `assert` runs for valid input combinations.
5. Cover both branches of any boolean-gated `count` or `for_each`.
6. Run `cd modules/<name> && terraform init -backend=false -input=false && terraform test` locally.
7. Ensure `make unit-tests` and `make lint` pass before opening a PR.
