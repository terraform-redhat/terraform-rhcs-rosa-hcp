# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

############################
# OCM Role
############################
module "ocm_role" {
  source = "../../modules/ocm-role"

  ocm_role_prefix = var.ocm_role_prefix
  profile         = var.profile
}
