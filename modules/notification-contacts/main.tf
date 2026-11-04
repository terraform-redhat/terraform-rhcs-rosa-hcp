# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

resource "rhcs_cluster_notification_contacts" "this" {
  cluster_id = var.cluster_id
  contacts   = var.contacts
}
