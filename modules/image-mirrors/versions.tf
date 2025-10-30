terraform {
  required_version = ">= 1.0"

  required_providers {
    rhcs = {
      version = ">= 1.7.2"
      source  = "terraform-redhat/rhcs"
    }
  }
}