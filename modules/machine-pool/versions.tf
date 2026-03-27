terraform {
  required_version = ">= 1.0"

  required_providers {
    rhcs = {
      version = ">= 1.7.3"
      source  = "terraform-redhat/rhcs"
    }
  }
}
