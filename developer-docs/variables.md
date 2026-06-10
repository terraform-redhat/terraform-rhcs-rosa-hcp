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
- MUST NOT: Pass nullable values to `contains()` — use `var.x == null ? true : contains(...)`.
- MUST: `contains()` validation → `nullable = true` (default) so explicit `null` fails validation, not silent default fallback.

WHEN provider field is a non-negative integer:
- MUST: Null-safe integer check — `var.x == null ? true : tonumber(var.x) == floor(var.x)`.
- MUST: Null-safe range check — `var.x == null ? true : var.x >= 0`.
- MUST: One check per `validation` block with a clear `error_message`.
DEFAULT: Follow provider numeric type and constraints;

**See:** [terraform-style-guide](https://github.com/hashicorp/agent-skills/tree/main/terraform) — [`CONTRIBUTING.md`](../CONTRIBUTING.md) wins on conflict; **refactor-module** skill for interface changes
