#!/bin/bash

set -e
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
TERRAFORM_DOCS_VERSION=v0.22.0
BINARY=terraform-docs
set +e
INSTALLED_TERRADOCS_VERSION="$(terraform-docs --version | head -1 | cut -d' ' -f3)"
set -e
if [[ "$TERRAFORM_DOCS_VERSION" != "$INSTALLED_TERRADOCS_VERSION" ]]; then
  curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-$(uname)-amd64.tar.gz
  tar -xzf terraform-docs.tar.gz terraform-docs
  chmod +x terraform-docs
  echo "sudo required for moving terraform-docs to /usr/local/bin"
  sudo mv terraform-docs /usr/local/bin/terraform-docs
  rm terraform-docs.tar.gz
else
  echo "${BINARY} ${TERRAFORM_DOCS_VERSION} already installed - skipping install"
fi
terraform-docs version
for d in . modules/* examples/*; do
  echo $d
  rm -rf $d/.terraform $d/.terraform.lock.hcl
  terraform-docs -c .terraform-docs.yml $d
done