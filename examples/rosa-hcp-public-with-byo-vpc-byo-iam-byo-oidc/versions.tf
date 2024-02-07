terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.35.0"
    }
    rhcs = {
      version = ">= 1.5.0"
      source  = "terraform-redhat/rhcs"
    }
  }
}
