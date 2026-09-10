# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.54.0"
    }
    rhcs = {
      version = "= 1.7.8"
      source  = "terraform-redhat/rhcs"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}
