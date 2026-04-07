# Review PR (Terraform — ROSA HCP module)

Run a **read-only** review suitable for merge decisions on **terraform-rhcs-rosa-hcp**.

**Invoke the `terraform-pr-reviewer` subagent** (`.cursor/agents/reviewer.md`) and supply:

1. **Git diff** — current branch vs `main` (or the diff the user cares about).
2. If available: **PR URL** (fetch description / pasted plan) or **verbatim `terraform plan`** from the PR body.

**Output:** Summary, **Low/Medium/High** risk, **findings** (one line each; caps; no duplicate of action-item fixes — see **Response format** in `.cursor/agents/reviewer.md`), and numbered **action items** — each with a **file path** (required); add **line** and/or **HCL block name** when reliable (lines are **revision-specific**).

Do not mix **ROSA Classic** patterns; this repository is **HCP only** (see `.cursor/rules/rosa-hcp-terraform.mdc`).
