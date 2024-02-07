resource "rhcs_identity_provider" "identity_provider" {
  cluster        = var.cluster_id
  name           = var.name
  github         = var.github
  gitlab         = var.gitlab
  google         = var.google
  htpasswd       = var.htpasswd
  ldap           = var.ldap
  openid         = var.openid
  mapping_method = var.mapping_method
}


