# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.45.0"
    }
    rhcs = {
      version = ">= 1.7.6"
      source  = "terraform-redhat/rhcs"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.3.0"
    }
  }
}
