terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38.0"
    }
    rhcs = {
      version = "= 1.6.8-prerelease.1"
      source  = "terraform-redhat/rhcs"
    }
  }
}
