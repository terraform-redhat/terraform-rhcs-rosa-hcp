#!/bin/bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

# Invoke via make terraform-docs (sets TERRAFORM_DOCS_BIN and TERRAFORM_DOCS_VERSION).

set -euo pipefail

if [[ -z "${TERRAFORM_DOCS_VERSION:-}" ]]; then
  echo "TERRAFORM_DOCS_VERSION is not set. Run via 'make terraform-docs' (versions are defined in the Makefile)." >&2
  exit 1
fi

if [[ -z "${TERRAFORM_DOCS_BIN:-}" ]]; then
  echo "TERRAFORM_DOCS_BIN is not set. Run via 'make terraform-docs'." >&2
  exit 1
fi

if [[ ! -x "${TERRAFORM_DOCS_BIN}" ]]; then
  echo "terraform-docs not found at ${TERRAFORM_DOCS_BIN}. Run: make tools (or make terraform-docs-bin)" >&2
  exit 1
fi

installed_version="$("${TERRAFORM_DOCS_BIN}" --version 2>/dev/null | head -1 | awk '{print $3}')"
if [[ "${installed_version}" != "${TERRAFORM_DOCS_VERSION}" ]]; then
  echo "terraform-docs ${installed_version} at ${TERRAFORM_DOCS_BIN}; Makefile requires ${TERRAFORM_DOCS_VERSION}. Run: make tools" >&2
  exit 1
fi

"${TERRAFORM_DOCS_BIN}" version
for d in . modules/* examples/*; do
  echo "$d"
  rm -rf "$d/.terraform" "$d/.terraform.lock.hcl"
  "${TERRAFORM_DOCS_BIN}" -c .terraform-docs.yml "$d"
done
