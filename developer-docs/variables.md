# Variables

- MUST: `type`, `description`, `default` when optional; `snake_case`; match existing `variables.tf` tone.
- MUST: Mirror [`terraform-redhat/rhcs`](https://github.com/terraform-redhat/terraform-provider-rhcs) schemas in variables and docs.
- MUST NOT: `count` / `for_each` from resource/data attributes that can be `null` after import — use `var.*`.
- PREFER: `map(object({ ... }))` with `optional(...)` over `map(any)` for homogeneous keyed objects.
- MUST: Root `validation` for cross-field rules; child modules may use `lifecycle` precondition.
- MUST NOT: Rename or retype variables without a migration plan.

WHEN adding `validation` or `lifecycle` precondition:
- MUST: only for simple checks (e.g. null/empty, enum membership, format, range).
DEFAULT: Let the **rhcs** provider enforce complex cross-field and business rules; do not duplicate or tighten them.

WHEN a variable description states a format constraint (e.g. "must begin with `/`", "must be a valid ARN"):
- MUST: Add a matching `validation` block — description documents intent, HCL enforces it. A description without a validation block silently accepts invalid values.

WHEN a variable maps to a field the ROSA CLI validates:
- MUST: Add the validation block — the ROSA CLI source is authoritative; existing modules that omit it have a gap, do not copy the gap.

WHEN `contains()` validates an **optional** value (null = unset):
- MUST: `var.x == null ? true : contains(...)` — avoids plan error on null.
- MUST: `nullable = true` (default).

DEFAULT: Null passes validation; provider/module logic treats null as unset.

**See:** [`modules/machine-pool/variables.tf`](../modules/machine-pool/variables.tf) — optional nested `capacity_reservation_preference`

WHEN `contains()` validates a **required** value (null = invalid):
- MUST: `nullable = true` (default).
- MUST NOT: `nullable = false` with a `default` — explicit `null` is silently replaced before validation.
- MUST: `contains(...)` without null short-circuit, OR `var.x != null && contains(...)` with a clear `error_message`.

DEFAULT: Explicit `null` fails validation with your `error_message`, not silent default substitution.

**See:** [`modules/idp/variables.tf`](../modules/idp/variables.tf) — required `idp_type` enum

WHEN `contains()` validation is present:
- MUST NOT: `nullable = false` + `default` + `contains()` **unless** null→default substitution is intentional and documented in the variable `description`.

WHEN provider field is a non-negative integer:
- MUST: Null-safe integer check — `var.x == null ? true : tonumber(var.x) == floor(var.x)`.
- MUST: Null-safe range check — `var.x == null ? true : var.x >= 0`.
- MUST: One check per `validation` block with a clear `error_message`.
DEFAULT: Follow provider numeric type and constraints; do not add integer/range checks the provider already enforces.

**See:** [terraform-style-guide](https://github.com/hashicorp/agent-skills/tree/main/terraform) — [`CONTRIBUTING.md`](../CONTRIBUTING.md) wins on conflict; **refactor-module** skill for interface changes
