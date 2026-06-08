#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ -z "${TERRAFORM_DOCS_BIN:-}" || -z "${TERRAFORM_DOCS_VERSION:-}" ]]; then
  echo "TERRAFORM_DOCS_BIN and TERRAFORM_DOCS_VERSION must be set. Run via 'make verify-gen'." >&2
  exit 1
fi

hash_readmes() {
  find . -name 'README.md' \
    ! -path './.vale/*' \
    ! -path '*/.terraform/*' \
    ! -path './.terraform-docs-cache/*' \
    ! -path './bin/*' \
    -print0 | sort -z | xargs -0 sha256sum 2>/dev/null | sort
}

before=$(mktemp)
after=$(mktemp)
trap 'rm -f "$before" "$after"' EXIT

hash_readmes >"$before"
TERRAFORM_DOCS_BIN="${TERRAFORM_DOCS_BIN}" TERRAFORM_DOCS_VERSION="${TERRAFORM_DOCS_VERSION}" bash scripts/terraform-docs.sh
hash_readmes >"$after"

if [[ "$(<"$before")" != "$(<"$after")" ]]; then
  echo "Generated docs are out of date. Run 'make terraform-docs' and commit the changes."
  exit 1
fi

rm -rf .terraform .terraform.lock.hcl
find modules examples -type d -name .terraform -prune -exec rm -rf {} +

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git status --porcelain | grep -v "Dockerfile")" ]]; then
    echo "It seems like you need to run 'make terraform-docs'. Please run it and commit the changes"
    git status --porcelain | grep -v "Dockerfile"
    exit 1
  fi
fi
