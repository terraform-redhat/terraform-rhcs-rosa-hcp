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
      source  = "terraform-redhat/rhcs"
      version = "= 1.7.8"
    }
  }
}
