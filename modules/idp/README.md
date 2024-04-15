# idp

## Introduction

This Terraform sub-module assists with the configuration of identity providers (IDPs) for ROSA HCP clusters. It offers support for various IDP types, including GitHub, GitLab, Google, HTPasswd, LDAP, and OpenID. With this module, you can seamlessly integrate external authentication mechanisms into your ROSA HCP clusters, enhancing security and user management capabilities. By enabling the configuration of different IDP types, you can tailor authentication methods to their specific requirements, ensuring flexibility and compatibility within the ROSA HCP cluster environment deployed on AWS.

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_identity_provider.github_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |
| [rhcs_identity_provider.gitlab_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |
| [rhcs_identity_provider.google_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |
| [rhcs_identity_provider.htpasswd_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |
| [rhcs_identity_provider.ldap_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |
| [rhcs_identity_provider.openid_identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_github_idp_ca"></a> [github\_idp\_ca](#input\_github\_idp\_ca) | Path to PEM-encoded certificate file to use when making requests to the server (optional). Valid only to Github Identity Provider (idp\_type=github) | `string` | `null` | no |
| <a name="input_github_idp_client_id"></a> [github\_idp\_client\_id](#input\_github\_idp\_client\_id) | Client secret issued by Github (required). Valid only to Github Identity Provider (idp\_type=github) | `string` | `null` | no |
| <a name="input_github_idp_client_secret"></a> [github\_idp\_client\_secret](#input\_github\_idp\_client\_secret) | Client secret issued by Github (required). Valid only to Github Identity Provider (idp\_type=github) | `string` | `null` | no |
| <a name="input_github_idp_hostname"></a> [github\_idp\_hostname](#input\_github\_idp\_hostname) | Optional domain to use with a hosted instance of GitHub Enterprise (optional). Valid only to Github Identity Provider (idp\_type=github) | `string` | `null` | no |
| <a name="input_github_idp_organizations"></a> [github\_idp\_organizations](#input\_github\_idp\_organizations) | Only users that are members of at least one of the listed organizations will be allowed to log in (optional). Valid only to Github Identity Provider (idp\_type=github) | `list(string)` | `null` | no |
| <a name="input_github_idp_teams"></a> [github\_idp\_teams](#input\_github\_idp\_teams) | Only users that are members of at least one of the listed teams will be allowed to log in. The format is `<org>`/`<team>` (optional). Valid only to Github Identity Provider (idp\_type=github) | `list(string)` | `null` | no |
| <a name="input_gitlab_idp_ca"></a> [gitlab\_idp\_ca](#input\_gitlab\_idp\_ca) | Trusted certificate authority bundle (optional). Valid only to Gitlab Identity Provider (idp\_type=gitlab) | `string` | `null` | no |
| <a name="input_gitlab_idp_client_id"></a> [gitlab\_idp\_client\_id](#input\_gitlab\_idp\_client\_id) | Client identifier of a registered Gitlab OAuth application (required). Valid only to Gitlab Identity Provider (idp\_type=gitlab) | `string` | `null` | no |
| <a name="input_gitlab_idp_client_secret"></a> [gitlab\_idp\_client\_secret](#input\_gitlab\_idp\_client\_secret) | Client secret issued by Gitlab (required). Valid only to Gitlab Identity Provider (idp\_type=gitlab) | `string` | `null` | no |
| <a name="input_gitlab_idp_url"></a> [gitlab\_idp\_url](#input\_gitlab\_idp\_url) | URL of the Gitlab instance (required). Valid only to Gitlab Identity Provider (idp\_type=gitlab) | `string` | `null` | no |
| <a name="input_google_idp_client_id"></a> [google\_idp\_client\_id](#input\_google\_idp\_client\_id) | Client identifier of a registered Google OAuth application (required). Valid only to Google Identity Provider (idp\_type=google) | `string` | `null` | no |
| <a name="input_google_idp_client_secret"></a> [google\_idp\_client\_secret](#input\_google\_idp\_client\_secret) | Client secret issued by Google (required). Valid only to Google Identity Provider (idp\_type=google) | `string` | `null` | no |
| <a name="input_google_idp_hosted_domain"></a> [google\_idp\_hosted\_domain](#input\_google\_idp\_hosted\_domain) | Restrict users to a Google Apps domain (optional). Valid only to Google Identity Provider (idp\_type=google) | `string` | `null` | no |
| <a name="input_htpasswd_idp_users"></a> [htpasswd\_idp\_users](#input\_htpasswd\_idp\_users) | A list of htpasswd user credentials (required). Valid only to Htpasswd Identity Provider (idp\_type=htpasswd) | <pre>list(object({<br>    username = string<br>    password = string<br>  }))</pre> | `null` | no |
| <a name="input_idp_type"></a> [idp\_type](#input\_idp\_type) | n/a | `string` | n/a | yes |
| <a name="input_ldap_idp_bind_dn"></a> [ldap\_idp\_bind\_dn](#input\_ldap\_idp\_bind\_dn) | DN to bind with during the search phase (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `string` | `null` | no |
| <a name="input_ldap_idp_bind_password"></a> [ldap\_idp\_bind\_password](#input\_ldap\_idp\_bind\_password) | Password to bind with during the search phase (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `string` | `null` | no |
| <a name="input_ldap_idp_ca"></a> [ldap\_idp\_ca](#input\_ldap\_idp\_ca) | Trusted certificate authority bundle (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `string` | `null` | no |
| <a name="input_ldap_idp_emails"></a> [ldap\_idp\_emails](#input\_ldap\_idp\_emails) | The list of attributes whose values should be used as the email address (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `list(string)` | `null` | no |
| <a name="input_ldap_idp_ids"></a> [ldap\_idp\_ids](#input\_ldap\_idp\_ids) | The list of attributes whose values should be used as the user ID. Default ['dn'] (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `list(string)` | `null` | no |
| <a name="input_ldap_idp_insecure"></a> [ldap\_idp\_insecure](#input\_ldap\_idp\_insecure) | Do not make TLS connections to the server (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `bool` | `null` | no |
| <a name="input_ldap_idp_names"></a> [ldap\_idp\_names](#input\_ldap\_idp\_names) | The list of attributes whose values should be used as the display name. Default ['cn'] (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `list(string)` | `null` | no |
| <a name="input_ldap_idp_preferred_usernames"></a> [ldap\_idp\_preferred\_usernames](#input\_ldap\_idp\_preferred\_usernames) | The list of attributes whose values should be used as the preferred username. Default ['uid'] (optional). Valid only to Ldap Identity Provider (idp\_type=ldap) | `list(string)` | `null` | no |
| <a name="input_ldap_idp_url"></a> [ldap\_idp\_url](#input\_ldap\_idp\_url) | An RFC 2255 URL which specifies the LDAP search parameters to use (required). Valid only to Ldap Identity Provider (idp\_type=ldap) | `string` | `null` | no |
| <a name="input_mapping_method"></a> [mapping\_method](#input\_mapping\_method) | Specifies how new identities are mapped to users when they log in. Options are add, claim, generate and lookup. (default is claim) | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the identity provider. | `string` | n/a | yes |
| <a name="input_openid_idp_ca"></a> [openid\_idp\_ca](#input\_openid\_idp\_ca) | Trusted certificate authority bundle (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `string` | `null` | no |
| <a name="input_openid_idp_claims_email"></a> [openid\_idp\_claims\_email](#input\_openid\_idp\_claims\_email) | List of claims to use as the email address (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `list(string)` | `null` | no |
| <a name="input_openid_idp_claims_groups"></a> [openid\_idp\_claims\_groups](#input\_openid\_idp\_claims\_groups) | List of claims to use as the groups names (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `list(string)` | `null` | no |
| <a name="input_openid_idp_claims_name"></a> [openid\_idp\_claims\_name](#input\_openid\_idp\_claims\_name) | List of claims to use as the display name (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `list(string)` | `null` | no |
| <a name="input_openid_idp_claims_preferred_username"></a> [openid\_idp\_claims\_preferred\_username](#input\_openid\_idp\_claims\_preferred\_username) | List of claims to use as the preferred username when provisioning a user (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `list(string)` | `null` | no |
| <a name="input_openid_idp_client_id"></a> [openid\_idp\_client\_id](#input\_openid\_idp\_client\_id) | Client ID from the registered application (required). Valid only to OpenID Identity Provider (idp\_type=openid) | `string` | `null` | no |
| <a name="input_openid_idp_client_secret"></a> [openid\_idp\_client\_secret](#input\_openid\_idp\_client\_secret) | Client Secret from the registered application (required). Valid only to OpenID Identity Provider (idp\_type=openid) | `string` | `null` | no |
| <a name="input_openid_idp_extra_authorize_parameters"></a> [openid\_idp\_extra\_authorize\_parameters](#input\_openid\_idp\_extra\_authorize\_parameters) | Extra authorization parameters for the OpenID Identity Provider (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `map(string)` | `null` | no |
| <a name="input_openid_idp_extra_scopes"></a> [openid\_idp\_extra\_scopes](#input\_openid\_idp\_extra\_scopes) | List of scopes to request, in addition to the 'openid' scope, during the authorization token request (optional). Valid only to OpenID Identity Provider (idp\_type=openid) | `list(string)` | `null` | no |
| <a name="input_openid_idp_issuer"></a> [openid\_idp\_issuer](#input\_openid\_idp\_issuer) | The URL that the OpenID Provider asserts as the Issuer Identifier. It must use the https scheme with no URL query parameters or fragment (required). Valid only to OpenID Identity Provider (idp\_type=openid) | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->