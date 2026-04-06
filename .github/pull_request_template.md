<!--
Please provide enough context so reviewers can understand:
1) the problem,
2) why this change is needed,
3) what changed,
4) how you validated it.

Use N/A when an item does not apply.

Commit format requirement:
[JIRA-TICKET] | [TYPE]: <MESSAGE>
TYPE must be one of:
feat, fix, docs, style, refactor, test, chore, build, ci, perf
For details, see: ./CONTRIBUTING.md
-->

## PR Summary
<!-- Briefly describe the most important changes and outcomes (1-2 lines). -->

## Detailed Description of the Issue
<!-- Describe the root problem, scope, impact, and user/business context for this Terraform module and its consumers. -->

## Related Issues and PRs
<!-- Link all tracking items and related code changes -->
- Jira: [OCM-XXXXX](https://jira.url/OCM-XXXXX)
- Fixes: `#`
- Related PR(s):
- Related design/docs:

## Type of Change
<!-- Check the primary type this PR represents -->
- [ ] feat - adds a new module capability or new user-facing behavior.
- [ ] fix - resolves incorrect module behavior or bug.
- [ ] docs - updates documentation only.
- [ ] style - formatting/naming changes with no logic impact.
- [ ] refactor - module code restructuring with no behavior change.
- [ ] test - adds or updates tests only.
- [ ] chore - maintenance work (tooling, housekeeping, non-product code).
- [ ] build - changes build system, packaging, or dependencies for build output.
- [ ] ci - changes CI pipelines, jobs, or automation workflows.
- [ ] perf - improves performance without changing intended behavior.

## Previous Behavior
<!-- Describe how the module behaved before this change. -->

## Behavior After This Change
<!-- Describe module behavior after this change (user-visible and non-user-visible). -->

## How to Test (Step-by-Step)
<!-- Provide reproducible validation instructions for module maintainers/reviewers -->

### Preconditions
<!-- Required setup: Terraform version, credentials, env vars (e.g. RHCS_TOKEN/AWS creds), provider versions, test data, etc. -->

### Test Steps
1.
2.
3.

### Expected Results
<!-- What should happen after running the steps above -->

## Proof of the Fix
<!-- Attach evidence that demonstrates the changed behavior -->
- Screenshots:
- Videos:
- Logs/CLI output:
- Other artifacts:

## Breaking Changes
- [ ] No breaking changes
- [ ] Yes, this PR introduces a breaking change (describe impact and migration plan below)

### Breaking Change Details / Migration Plan
<!-- Required only when breaking changes are introduced.
Examples: variable rename/removal, output rename/removal, default value change, resource behavior changes, provider/version requirement changes. -->

## Developer Verification Checklist
- [ ] **AWS-only changes:** If this PR is mainly **AWS-only** (no `rhcs` resources/variables), I linked **official Red Hat or cited ROSA HCP documentation** that supports reference alignment, or I explained why the change still belongs in-repo per **Module scope (AWS-only vs core HCP)** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc).
- [ ] I checked if this affects terraform-rhcs-rosa-classic and submitted (or already submitted) a companion PR when needed.
- [ ] Commit subject/title follows `[JIRA-TICKET] | [TYPE]: <MESSAGE>`.
- [ ] PR description clearly explains both **what** changed and **why**.
- [ ] Relevant Jira/GitHub issues and related PRs are linked.
- [ ] Tests were added/updated where appropriate.
- [ ] I manually tested the change.
- [ ] `make verify` passes.
- [ ] `make verify-gen` passes.
- [ ] Documentation was added/updated where appropriate (see `make terraform-docs`).
- [ ] Any risk, limitation, or follow-up work is documented.
