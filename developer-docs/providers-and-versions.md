# Providers and versions

- MUST: Root `versions.tf` lists minimum **rhcs** and **aws** (and any other) provider versions for the **entire** tree (root + all `modules/**`).
- MUST: Raise root floor when any submodule raises `required_providers` — root must not be lower than any submodule.
- MUST: Confirm new AWS resources/data sources exist in the **aws** provider range declared in `versions.tf`.

WHEN a feature is OpenShift version-gated:

- MUST: Document minimum OpenShift version in variable `description` and README.

DEFAULT: No extra version callout beyond what the **rhcs** provider schema requires.

**See:** [`submodules.md`](submodules.md)
