#!/bin/bash

set -e
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
TERRAFORM_DOCS_VERSION=v0.22.0
BINARY=terraform-docs
set +e
INSTALLED_TERRADOCS_VERSION="$(terraform-docs --version | head -1 | cut -d' ' -f3)"
PLATFORM=$( uname | tr '[:upper:]' '[:lower:]')
set -e
if [[ "$TERRAFORM_DOCS_VERSION" != "$INSTALLED_TERRADOCS_VERSION" ]]; then
  curl -sSLo ./terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-amd64.tar.gz https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-amd64.tar.gz
  curl -sSLo ./terraform-docs.tar.gz.sha256sum https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}.sha256sum
  if sha256sum --ignore-missing -c "terraform-docs.tar.gz.sha256sum"; then
    echo "File verification successful"
  else
    echo "File verification failed" >&2
    exit 1
  fi
  tar -xzf terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-amd64.tar.gz terraform-docs
  chmod +x terraform-docs
  echo "sudo required for moving terraform-docs to /usr/local/bin"
  sudo mv terraform-docs /usr/local/bin/terraform-docs
  rm terraform-docs-${TERRAFORM_DOCS_VERSION}-${PLATFORM}-amd64.tar.gz ./terraform-docs.tar.gz.sha256sum
else
  echo "${BINARY} ${TERRAFORM_DOCS_VERSION} already installed - skipping install"
fi
terraform-docs version
for d in . modules/* examples/*; do
  echo $d
  rm -rf $d/.terraform $d/.terraform.lock.hcl
  terraform-docs -c .terraform-docs.yml $d
done

