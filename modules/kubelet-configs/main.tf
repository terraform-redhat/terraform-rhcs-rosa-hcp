# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

resource "rhcs_kubeletconfig" "rosa_kubeletconfig" {
  cluster        = var.cluster_id
  name           = var.name
  pod_pids_limit = var.pod_pids_limit
}