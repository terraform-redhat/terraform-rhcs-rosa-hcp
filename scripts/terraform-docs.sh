#!/bin/bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0


set -e
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
TERRAFORM_DOCS_VERSION=v0.22.0
BINARY=terraform-docs
set +e
INSTALLED_TERRADOCS_VERSION="$(terraform-docs --version 2> /dev/null | head -1 | cut -d' ' -f3)"
ARCH="$(uname -m)" && if [[ ${ARCH} == "x86_64" ]]; then export ARCH="amd64"; elif [[ ${ARCH} == "aarch64" ]]; then export ARCH="arm64"; fi 
PLATFORM=$( uname | tr '[:upper:]' '[:lower:]')
set -e
if [[ "$TERRAFORM_DOCS_VERSION" != "$INSTALLED_TERRADOCS_VERSION" ]]; then
  echo "Installing terraform-docs ${TERRAFORM_DOCS_VERSION}"
  curl -sSLo ./terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-${ARCH}.tar.gz https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-${ARCH}.tar.gz
  curl -sSLo ./terraform-docs.tar.gz.sha256sum https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}.sha256sum
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    echo "sha256sum and shasum notfound" >&2
    exit 1
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    SHA_VERIFY=(sha256sum --ignore-missing -c "terraform-docs.tar.gz.sha256sum")
  else
    SHA_VERIFY=(shasum --ignore-missing -a 256 -c "terraform-docs.tar.gz.sha256sum")
  fi
  if "${SHA_VERIFY[@]}"; then
    echo "File verification successful"
  else
    echo "File verification failed" >&2
    exit 1
  fi
  tar -xzf terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-${ARCH}.tar.gz terraform-docs
  chmod +x terraform-docs
  echo "sudo required for moving terraform-docs to /usr/local/bin"
  sudo mv terraform-docs /usr/local/bin/terraform-docs
  rm terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-${ARCH}.tar.gz ./terraform-docs.tar.gz.sha256sum
else
  echo "${BINARY} ${TERRAFORM_DOCS_VERSION} already installed - skipping install"
fi
terraform-docs version
for d in . modules/* examples/*; do
  echo $d
  rm -rf $d/.terraform $d/.terraform.lock.hcl
  terraform-docs -c .terraform-docs.yml $d
done

