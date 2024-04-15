#!/bin/bash

set -e

for d in . modules/* examples/*; do
  echo $d
  rm -rf $d/.terraform $d/.terraform.lock.hcl
  terraform-docs -c .terraform-docs.yml $d
done
