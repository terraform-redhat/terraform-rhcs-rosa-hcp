#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

# This script adds Apache 2.0 license headers to source files
# Usage:
#   ./add-license-header.sh          # Add headers to files
#   ./add-license-header.sh -check   # Check for missing headers (returns non-zero if headers are missing)
#
# Invoke via make (sets ADDLICENSE_BIN to bin/addlicense from the Makefile).

set -euo pipefail

ADDLICENSE_VERSION="${ADDLICENSE_VERSION:-v1.2.0}"

if [[ -z "${ADDLICENSE_BIN:-}" ]]; then
  echo "ADDLICENSE_BIN is not set. Run via 'make license-check' or 'make license-add'." >&2
  exit 1
fi

if [[ ! -x "${ADDLICENSE_BIN}" ]]; then
  echo "addlicense not found at ${ADDLICENSE_BIN}. Run: make tools (or make license-check-bin)" >&2
  exit 1
fi

CHECK_MODE=""
if [[ $# -gt 0 ]]; then
  if [[ "$1" == "-check" ]]; then
    CHECK_MODE="-check"
  else
    echo "Usage: $0 [-check]" >&2
    exit 1
  fi
fi

"${ADDLICENSE_BIN}" ${CHECK_MODE} \
  -c "Red Hat" \
  -l apache \
  -y "" \
  -s=only \
  -ignore "**/*.md" \
  -ignore "**/*.yaml" \
  -ignore "**/*.yml" \
  -ignore "**/*.toml" \
  -ignore "**/Dockerfile" \
  -ignore ".tflint.hcl" \
  -ignore "**/.terraform/**" \
  -ignore "**/.terraform.lock.hcl" \
  -ignore "bin/**" \
  .
