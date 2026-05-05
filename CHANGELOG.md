## 1.7.3 (20 Apr, 2026)

FEATURES:
   * Add capacity_reservation_id and capacity_reservation_preference
   * Add rhcs_log_forwarder
   * Adding external id to installer role and cluster

ENHANCEMENTS:
 * Bug fixes
   * Change rhcs_hcp_default_ingress to fall back to var.wait_for_create_complete
   * Change capacity_reservation_preference to safely accept null
   * Replace machine_pools map(any) with map(object)
   * Replace log_forwarders map(any) with map(object)
   * Fix OWNERS to add olucasfreitas
   * Added support for external_auth_providers_enabled flag
 * Chores
   * Remove 'ok-to-test' labels from package rules
   * Update Terraform Docs version and download URL
   * Update Renovate configuration with new limits and options
   * Update renovate.json to modify package rules
   * Fix formatting of ignorePaths in renovate.json
   * Enable dependency dashboard in renovate.json
   * Refactor packageRules in renovate.json
   * Add minimumReleaseAge to renovate configuration
   * Add renovate and tests
   * Add willkutler to OWNERS list
   * Add issue template
   * Add contributor and AI assistant documentation
   * Bump terraform-docs to 0.21.0
   * Format terraform files
 * Documentation
   * Update terraform-docs after deps bump
   * Update terraform-docs after deps bump
   * Update ROSA HCP documentation to clarify module scope for AWS-only configurations
   * Add Contributing and PR template
 * Other
   * Update dependency terraform-docs/terraform-docs to v0.22.0
   * Implement OCM-23042 additional sec group to PrivateLink Endpoint
   * Add lufreita to the list of owners
   * Add amandahla to the list of owners


## 1.7.2 (13 Feb, 2026)

ENHANCEMENTS:
 * Bug fixes
   * Allow setting billing accounts in FedRAMP
   * Oidc_prefix validation makes the cluster creation failure
   * Fix HCP E2E test issues
 * Other
   * Update OWNERS to include jerichokeyne
   * Adding oidc-prefix to HCP module
   * Support ROSA GovCloud HCP clusters
   * Adding support for govcloud to the bastion host module

## 1.7.1 (30 Oct, 2025)

FEATURES:
   * Support for image registry mirrors

ENHANCEMENTS:
 * Chores
   * Add temp owners to facilitate idms dev

## 1.7.0 (25 Aug, 2025)

FEATURES:
   * Include shared vpc support and example

ENHANCEMENTS:
 * Bug fixes
   * Adjust TF docs to 0.17.0 `terraform-docs`
   * Adds the domain_prefix variable to the ROSA HCP module
   * Make AWS provider version gated >6.0
   * Bump hashicorp/aws to >5.4 and generate docs
 * Chores
   * Update TF docs with right TF-docs version
   * Update example cluster versions and add descriptions to variables
 * Other
   * Fixing additional instances of deprecated aws_region.current.name to aws_region.current.region
   * Changing data source aws_region.current.name to aws_region.current.region as name is deprecated - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
   * Make 'additional_security_group_ids' optional
   * Run 'makefile terraform-docs'

## 1.6.9 (16 Jul, 2025)

ENHANCEMENTS:
 * Bug fixes
   * Apply bucket policy after public access settings
   * Add additional SGs to nodepool examples

## 1.6.8 (13 May, 2025)

FEATURES:
   * Include bastion host module
   * Include indicator for bypassing machine pool deletion errors
   * Day1 additional SG support for HCP
   * Parity to classic cluster modules outputs

ENHANCEMENTS:
 * Bug fixes
   * Add additional SGs to nodepool examples
   * Operator roles forcing replace
   * Sort subnet ids output
   * Adjust version on multiple machine pools example
   * Public multiple mps and idps example usage
   * 'ack_for' variable should be a string
 * Chores
   * Add 'hunterkepley' to OWNERS file + add `idea/*` to gitignore
   * Fix readme typo

## 1.6.5 (24 Oct, 2024)

ENHANCEMENTS:
 * Bug fixes
   * Sort subnet ids output
 * Chores
   * Fix readme typo

## 1.6.4 (03 Oct, 2024)

FEATURES:
   * Support create kubelet configs from the main module
   * Parity to classic cluster modules outputs
   * Add sensitive to passwords/secret attributes
   * Expose availability_zones as a parameter in vpc sub-module
   * Add sub modules of kubelet configs
   * Add imdsv2 support into rhcs hcp module
   * Support cluster admin day-1 creation for ROSA HCP
   * Add outputs.tf to examples
   * Add more outputs from sub modules in root
   * Allow to define multiple machine pools and idps

ENHANCEMENTS:
 * Bug fixes
   * Public multiple mps and idps example usage
   * 'ack_for' variable should be a string
   * Check account role prefix is not empty to setup random part
   * Ensure operator role prefix var for submodule is mandatory
   * Only takes the variable when not empty
   * Remove unused folder in exmaple
   * Adjust modules version >= 1.6.2
   * Allow to supply auto_repair to the machine pool in module

## 1.6.3 (28 Aug, 2024)

ENHANCEMENTS:
 * Bug fixes
   * Adjust modules version >= 1.6.2

## 1.6.2 (27 May, 2024)

FEATURES:
   * Add capacity_reservation_id and capacity_reservation_preference
   * Add rhcs_log_forwarder
   * Adding external id to installer role and cluster
   * Support for image registry mirrors
   * Include shared vpc support and example
   * Include bastion host module
   * Day1 additional SG support for HCP
   * Include indicator for bypassing machine pool deletion errors
   * Parity to classic cluster modules outputs
   * Support create kubelet configs from the main module
   * Add sensitive to passwords/secret attributes
   * Expose availability_zones as a parameter in vpc sub-module
   * Add sub modules of kubelet configs
   * Add imdsv2 support into rhcs hcp module
   * Support cluster admin day-1 creation for ROSA HCP
   * Add outputs.tf to examples
   * Add more outputs from sub modules in root
   * Allow to define multiple machine pools and idps
   * Include example usage and registry source
   * Allow to supply tuning configs to the machine pool
   * Adjust review comments from pre release
   * Add variable for wait std compute nodes
   * Remove aws module dependency oidc config
   * Remove aws module dependency to acc/operator roles creation
   * Add tf hcp modules

ENHANCEMENTS:
 * Bug fixes
   * Change rhcs_hcp_default_ingress to fall back to var.wait_for_create_complete
   * Change capacity_reservation_preference to safely accept null
   * Replace machine_pools map(any) with map(object)
   * Replace log_forwarders map(any) with map(object)
   * Fix OWNERS to add olucasfreitas
   * Added support for external_auth_providers_enabled flag
   * Allow setting billing accounts in FedRAMP
   * Oidc_prefix validation makes the cluster creation failure
   * Fix HCP E2E test issues
   * Adjust TF docs to 0.17.0 `terraform-docs`
   * Adds the domain_prefix variable to the ROSA HCP module
   * Make AWS provider version gated >6.0
   * Bump hashicorp/aws to >5.4 and generate docs
   * Apply bucket policy after public access settings
   * Add additional SGs to nodepool examples
   * Operator roles forcing replace
   * Sort subnet ids output
   * Public multiple mps and idps example usage
   * 'ack_for' variable should be a string
   * Adjust version on multiple machine pools example
   * Check account role prefix is not empty to setup random part
   * Ensure operator role prefix var for submodule is mandatory
   * Only takes the variable when not empty
   * Remove unused folder in exmaple
   * Adjust modules version >= 1.6.2
   * Allow to supply auto_repair to the machine pool in module
   * Include changes to password generation in module
   * Include message to oidc mentioning managed shouldn't be changed
   * Include message to vpc mentioning values shouldn't be changed
   * Adjust autoscaler docs to mention it is not currently available
   * Aws_subnet_ids nullable false
   * Move source back to local ref and adjust example usage completeness
   * Qe review comments for 1.6.2-prerelease.1
   * Adjust support trust policy to have isolated sre role as principal
   * Reduce delay back and adjust order of dependency in oidc config
   * Increase VPC destroy delay for AWS propagation
   * Adjust dockerfile to include terraform-docs
   * Adjust docs
   * Remove local refs and bump rhcs provider to 1.6.0
 * Chores
   * Change coderabbit config to use inheritance
   * Enable gitleaks (secret scanner)
   * Change terraform-docs to make sure that runs same version as in ci
   * Add coderabbit configuration file
   * Remove 'ok-to-test' labels from package rules
   * Update Terraform Docs version and download URL
   * Update Renovate configuration with new limits and options
   * Update renovate.json to modify package rules
   * Fix formatting of ignorePaths in renovate.json
   * Enable dependency dashboard in renovate.json
   * Refactor packageRules in renovate.json
   * Add minimumReleaseAge to renovate configuration
   * Add renovate and tests
   * Add willkutler to OWNERS list
   * Add issue template
   * Add contributor and AI assistant documentation
   * Bump terraform-docs to 0.21.0
   * Format terraform files
   * Add temp owners to facilitate idms dev
   * Update TF docs with right TF-docs version
   * Update example cluster versions and add descriptions to variables
   * Add 'hunterkepley' to OWNERS file + add `idea/*` to gitignore
   * Fix readme typo
 * Documentation
   * Update terraform-docs after deps bump
   * Update terraform-docs after deps bump
   * Update terraform-docs after deps bump
   * Update terraform-docs after deps bump
   * Update ROSA HCP documentation to clarify module scope for AWS-only configurations
   * Add Contributing and PR template
 * Other
   * Update dependency terraform-docs/terraform-docs to v0.22.0
   * Implement OCM-23042 additional sec group to PrivateLink Endpoint
   * Add lufreita to the list of owners
   * Add amandahla to the list of owners
   * Update OWNERS to include jerichokeyne
   * Adding oidc-prefix to HCP module
   * Support ROSA GovCloud HCP clusters
   * Adding support for govcloud to the bastion host module
   * Fixing additional instances of deprecated aws_region.current.name to aws_region.current.region
   * Changing data source aws_region.current.name to aws_region.current.region as name is deprecated - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
   * Make 'additional_security_group_ids' optional
   * Run 'makefile terraform-docs'
   * Initial commit
