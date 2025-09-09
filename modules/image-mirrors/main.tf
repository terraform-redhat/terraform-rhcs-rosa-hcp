resource "rhcs_image_mirror" "image_mirror" {
  cluster_id = var.cluster_id
  type       = var.type
  source     = var.source_registry
  mirrors    = var.mirrors
}