# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

output "image_mirror_id" {
  description = "The unique identifier of the image mirror."
  value       = rhcs_image_mirror.image_mirror.id
}