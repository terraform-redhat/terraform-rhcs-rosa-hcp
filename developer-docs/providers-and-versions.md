# Providers and versions

## Consumer floors (`required_providers`)

Provider floors are **minimum** versions (`>= …`), not pins.

- **Root is the ceiling** — [`versions.tf`](../versions.tf) sets the highest AWS floor any submodule may declare. Today: `aws >= 6.51.0` (also `null >= 3.3.0`; `rhcs` Renovate-managed).
- **Submodules may be lower** — a submodule’s `versions.tf` may use any AWS floor **≤ root** when that is enough for its own HCL (for example `operator-roles` at `>= 5.38.0`). Do not raise a submodule to match root “for consistency.”
- **Never exceed root** — if a submodule needs an AWS version **above** the current root floor, **bump root first**, then raise that submodule. Root must always be `>=` every submodule floor in `modules/**`.
- **Customer impact** — bump floors only when HCL (or a pinned registry module) truly requires it. Do not raise floors for Renovate churn or transitive drift.

### Why floors differ (examples, not an inventory)

These are **illustrative** reasons floors diverge — not a complete list of every module’s current constraint. Check each module’s `versions.tf` for the actual floor.

| Why the floor is higher | Example modules | Typical floor |
|-------------------------|-----------------|---------------|
| Root graph needs recent AWS features | Root module | `>= 6.51.0` |
| Uses `data.aws_region.current.region` (AWS 6.0+) | `oidc-config-and-provider`, `vpc`, `rosa-cluster-hcp`, … | `>= 6.0.0` |
| Older AWS APIs suffice | `operator-roles`, `bastion-host`, shared-vpc role modules, … | below root (e.g. `>= 5.x` / `>= 4.x`) |

- MUST: Confirm new AWS resources/data sources exist in the **aws** provider range declared in the relevant `versions.tf`.
- Provider floor changes are **minor** semver events for the module (see release notes).

### RHCS feature floors

WHEN adding an `rhcs` resource or argument introduced in provider release `X`:

- MUST: Update `required_providers.rhcs` to `>= X` in the root module and every feature-owning submodule.
- MUST NOT: Rely on the root constraint for a public submodule; direct submodule consumers resolve that submodule's own constraint.
- MUST: Regenerate the README for each submodule whose provider constraint changes.

Registry module pins under `modules/**` are **exact versions**, bumped **manually**, so upstream module releases do not force customer AWS provider upgrades unrelated to this module.

## Renovate

| Target | Renovate behavior |
|--------|-------------------|
| **Root `versions.tf` — rhcs** | Auto-bump `required_providers` floor |
| **Root `versions.tf` — aws, null, …** | **Disabled** — manual only |
| **`examples/**/versions.tf` — aws, rhcs** | Auto-**pin** and bump exact versions (`rangeStrategy: pin`) |
| **`modules/**` — providers and module pins** | **Disabled** — manual only |

WHEN a provider or registry module bump would raise the customer-facing floor, treat it as a deliberate maintainer decision with release-note impact — not something Renovate should do silently.

## CI verification

| Pass | What `make verify` does |
|------|-------------------------|
| **Pinned** | Each example `versions.tf` exact pins → `terraform init` + `validate` |
| **Floor** | Same example with AWS constraint temporarily set to `examples/*/.aws-provider-floor` → `init` + `validate` |

- Each example **must** have `examples/<name>/.aws-provider-floor` (one line, e.g. `6.51.0` for root-module examples or `6.0.0` for `ocm-role`).
- Floor values document the **minimum AWS version that example’s graph needs**.
- Lock files are **not** committed (gitignored; ephemeral in CI).
- **Prow `run-example`** uses the example’s pinned providers from `examples/**/versions.tf`.

GitHub Actions **`verify-min-terraform.yml`** runs `make verify` at Terraform **1.5.7** (module minimum).

WHEN a feature is OpenShift version-gated:

- MUST: Document minimum OpenShift version in variable `description` and README.

**See:** [`submodules.md`](submodules.md)
