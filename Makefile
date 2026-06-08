SHELL := bash

LOCALBIN ?= $(CURDIR)/bin
LOCALBIN_ABS := $(abspath $(LOCALBIN))
MODULE_REGISTRY := terraform-redhat/rosa-hcp/rhcs

# renovate: datasource=github-releases depName=google/addlicense
ADDLICENSE_VERSION ?= v1.2.0
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
TERRAFORM_DOCS_VERSION ?= v0.24.0
# renovate: datasource=github-releases depName=terraform-linters/tflint
TFLINT_VERSION ?= v0.62.1
# renovate: datasource=github-releases depName=vale-cli/vale
VALE_VERSION ?= v3.14.2
# renovate: datasource=github-releases depName=bridgecrewio/checkov
CHECKOV_VERSION ?= 3.2.529
# renovate: datasource=github-releases depName=gitleaks/gitleaks
GITLEAKS_VERSION ?= v8.30.1

CHECKOV_CONFIG ?= checkov.yaml
GITLEAKS_CONFIG ?= .gitleaks.toml

ifeq ($(shell go env GOOS 2>/dev/null),windows)
	BIN_EXT=.exe
else
	BIN_EXT=
endif

ADDLICENSE := $(LOCALBIN)/addlicense$(BIN_EXT)
TERRAFORM_DOCS := $(LOCALBIN)/terraform-docs$(BIN_EXT)
TFLINT := $(LOCALBIN)/tflint$(BIN_EXT)
VALE := $(LOCALBIN)/vale$(BIN_EXT)
CHECKOV := $(LOCALBIN)/checkov$(BIN_EXT)
GITLEAKS := $(LOCALBIN)/gitleaks$(BIN_EXT)

export PATH := $(LOCALBIN_ABS):$(PATH)

$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"

$(ADDLICENSE): | $(LOCALBIN)
	bash hack/install-release-tool.sh addlicense "$(ADDLICENSE_VERSION)" "$(LOCALBIN_ABS)"

$(VALE): | $(LOCALBIN)
	bash hack/install-release-tool.sh vale "$(VALE_VERSION)" "$(LOCALBIN_ABS)"

$(TFLINT): | $(LOCALBIN)
	bash hack/install-release-tool.sh tflint "$(TFLINT_VERSION)" "$(LOCALBIN_ABS)"

$(TERRAFORM_DOCS): | $(LOCALBIN)
	bash hack/install-release-tool.sh terraform-docs "$(TERRAFORM_DOCS_VERSION)" "$(LOCALBIN_ABS)"

$(CHECKOV): | $(LOCALBIN)
	bash hack/install-release-tool.sh checkov "$(CHECKOV_VERSION)" "$(LOCALBIN_ABS)"

$(GITLEAKS): | $(LOCALBIN)
	bash hack/install-release-tool.sh gitleaks "$(GITLEAKS_VERSION)" "$(LOCALBIN_ABS)"

.PHONY: tools addlicense vale tflint terraform-docs-bin license-check-bin security-check-bin checkov gitleaks
tools: $(ADDLICENSE) $(VALE) $(TFLINT) $(TERRAFORM_DOCS)

addlicense: $(ADDLICENSE)
vale: $(VALE)
tflint: $(TFLINT)
terraform-docs-bin: $(TERRAFORM_DOCS)
license-check-bin: $(ADDLICENSE)
security-check-bin: $(CHECKOV) $(GITLEAKS)
checkov: $(CHECKOV)
gitleaks: $(GITLEAKS)

# Merge gate: verify, verify-gen, lint, unit-tests, license-check, docs-lint (fail-fast).
# Intended single OpenShift Prow presubmit after openshift/release switches from verify + verify-gen.
.PHONY: pre-push-checks
pre-push-checks: tools
	@$(MAKE) --no-print-directory verify
	@$(MAKE) --no-print-directory verify-gen
	@$(MAKE) --no-print-directory lint
	@$(MAKE) --no-print-directory unit-tests
	@$(MAKE) --no-print-directory license-check
	@$(MAKE) --no-print-directory docs-lint

# Prow today (until consolidated): verify-format → make verify, verify-gen → make verify-gen.
# https://github.com/openshift/release/tree/master/ci-operator/config/terraform-redhat/terraform-rhcs-rosa-hcp
.PHONY: verify
verify:
	@set -euo pipefail; \
	for d in examples/*/; do \
		echo "!! Validating $$d !!"; \
		( cd "$$d" && rm -rf .terraform .terraform.lock.hcl && terraform init -backend=false -input=false && terraform validate ); \
	done

.PHONY: verify-gen
verify-gen: $(TERRAFORM_DOCS)
	@TERRAFORM_DOCS_BIN="$(TERRAFORM_DOCS)" TERRAFORM_DOCS_VERSION="$(TERRAFORM_DOCS_VERSION)" bash scripts/verify-gen.sh

.PHONY: lint
lint: $(TFLINT)
	terraform fmt -check -recursive
	@set -euo pipefail; \
	rm -rf .terraform .terraform.lock.hcl; \
	tmp=$$(mktemp -d); \
	TF_DATA_DIR="$$tmp" terraform init -backend=false -input=false; \
	ln -sfn "$$tmp" .terraform
	"$(TFLINT)" --init
	"$(TFLINT)" --recursive \
		--minimum-failure-severity=error \
		--disable-rule=terraform_required_providers \
		--disable-rule=terraform_unused_declarations \
		--disable-rule=terraform_unused_required_providers

.PHONY: unit-tests
unit-tests:
	@set -e; \
	for submodule in modules/*; do \
	  echo "== $$submodule =="; \
	  cd "$$submodule/tests" 2>/dev/null || continue; \
	  echo "== running tests for $$submodule =="; \
	  (cd .. && terraform init -backend=false -input=false && terraform test); \
	  cd ../../..; \
	done

.PHONY: license-check
license-check: $(ADDLICENSE)
	@ADDLICENSE_BIN="$(ADDLICENSE)" ADDLICENSE_VERSION="$(ADDLICENSE_VERSION)" bash scripts/add-license-header.sh -check

.PHONY: license-add
license-add: $(ADDLICENSE)
	@ADDLICENSE_BIN="$(ADDLICENSE)" ADDLICENSE_VERSION="$(ADDLICENSE_VERSION)" bash scripts/add-license-header.sh

.PHONY: docs-lint
docs-lint: $(VALE)
	@echo "Note: README and module docs are generated with 'make terraform-docs'; fix descriptions in *.tf, then run 'make verify-gen'."
	@docs=$$(find . -name '*.md' \
		-not -path './.vale/*' \
		-not -path '*/.terraform/*' \
		-not -path './.terraform-docs-cache/*' \
		-not -path './bin/*'); \
	if [ -z "$$docs" ]; then \
		echo "No Markdown files found for docs-lint"; \
		exit 1; \
	fi; \
	"$(VALE)" --minAlertLevel=error $$docs

# Security (not in pre-push-checks): Gitleaks secret scan + Checkov Terraform static analysis.
# Excludes modules/rosa-cluster-hcp (Checkov cannot parse multiline lifecycle preconditions there).
.PHONY: security-check
security-check: $(GITLEAKS) $(CHECKOV)
	@set -euo pipefail; \
	echo "== Gitleaks secret scan =="; \
	"$(GITLEAKS)" detect --source . --config "$(GITLEAKS_CONFIG)" --no-banner --no-git; \
	echo "== Checkov Terraform static analysis =="; \
	echo "Note: Checkov cannot parse modules/rosa-cluster-hcp/main.tf (lifecycle preconditions). That file is skipped directly; examples may still report one parsing error via the root module — use make verify for cluster wiring."; \
	"$(CHECKOV)" -d examples --config-file "$(CHECKOV_CONFIG)" --skip-download --quiet; \
	for d in modules/*/; do \
	  case "$$d" in */rosa-cluster-hcp/) \
	    echo "Skipping Checkov for $$d (lifecycle precondition parse limitation; use make verify)"; \
	    continue ;; \
	  esac; \
	  "$(CHECKOV)" -d "$$d" --config-file "$(CHECKOV_CONFIG)" --skip-download --quiet; \
	done; \
	root_tf=$$(find . -maxdepth 1 -name '*.tf' -print); \
	if [ -n "$$root_tf" ]; then \
	  "$(CHECKOV)" $$(printf ' -f %s' $$root_tf) --config-file "$(CHECKOV_CONFIG)" --skip-download --quiet; \
	fi

.PHONY: terraform-docs
terraform-docs: $(TERRAFORM_DOCS)
	@TERRAFORM_DOCS_BIN="$(TERRAFORM_DOCS)" TERRAFORM_DOCS_VERSION="$(TERRAFORM_DOCS_VERSION)" bash scripts/terraform-docs.sh

.PHONY: commits/check
commits/check:
	@./hack/commit-msg-verify.sh

# OpenShift Prow example jobs (rhcs-module-run-example-hcp): make run-example EXAMPLE_NAME=...
.PHONY: run-example
run-example:
	bash scripts/run-example.sh $(EXAMPLE_NAME)

# Maintainer utilities (not part of pre-push-checks).
.PHONY: dev-environment registry-environment change-ocp-version change-module-version
dev-environment:
	find . -type f -name "versions.tf" -exec sed -i -e "s/terraform-redhat\/rhcs/terraform.local\/local\/rhcs/g" -- {} +

registry-environment:
	find . -type f -name "versions.tf" -exec sed -i -e "s/terraform.local\/local\/rhcs/terraform-redhat\/rhcs/g" -- {} +

change-ocp-version:
	find . -type f -name "variables.tf" -exec sed -i -e 's/default = "$(OLD_VER)"/default = "$(NEW_VER)"/g' -- {} +

change-module-version:
	find ./examples -type f -name '*.tf' -exec sed -i 's^source\s*= "\.\./\.\./"^source = "$(MODULE_REGISTRY)"\n  version = "$(MODULE_VERSION)"^g' -- {} +
	find ./examples -type f -name '*.tf' -exec sed -E -i 's^source\s*= "\.\./\.\./modules/([^"]+)"^source = "$(MODULE_REGISTRY)//modules/\1"\n  version = "$(MODULE_VERSION)"^g' -- {} +

.PHONY: tests
tests:
	sh tests.sh
