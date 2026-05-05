#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

# This script adds Apache 2.0 license headers to source files
# Usage:
#   ./add-license-header.sh          # Add headers to files
#   ./add-license-header.sh -check   # Check for missing headers (returns non-zero if headers are missing)

set -euo pipefail

ADDLICENSE_VERSION="v1.2.0"

# Check if addlicense is installed
if ! command -v addlicense &> /dev/null; then
    echo "Error: addlicense is not installed."
    echo "Install it with: go install github.com/google/addlicense@${ADDLICENSE_VERSION}"
    exit 1
fi

# Parse arguments
CHECK_MODE=""
if [[ $# -gt 0 ]] && [[ "$1" == "-check" ]]; then
    CHECK_MODE="-check"
fi

# Run addlicense
addlicense ${CHECK_MODE} \
    -c "ROSA Authors" \
    -l apache \
    -y "" \
    -s=only \
    -ignore "**/*.md" \
    -ignore "**/*.yaml" \
    -ignore "**/*.yml" \
    -ignore "**/*.toml" \
    -ignore "**/Dockerfile" \
    -ignore ".tflint.hcl" \
    .
