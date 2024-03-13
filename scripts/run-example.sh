#!/bin/bash

set -e

function runexample::usage() {
	echo "Usage:

	./run-example.sh <example_name> [option]
  When option can be one of:
  * --apply-only
  * --destroy-only
	"
}

if (( "$#" < 1  || "$#" > 2)); then
	echo "Error:
	Unsupported command!!!
	"
        runexample::usage
	exit 1
fi

##############################################################
# Change directory to example directory given in arg $1
##############################################################
example_name=$1

REPO_ROOT_DIR="$( cd -- "$(dirname "$1")" >/dev/null 2>&1 ; pwd -P )"
EXAMPLE_PATH="${REPO_ROOT_DIR}/examples/${example_name}"
if [ ! -d "${EXAMPLE_PATH}" ]; then
	echo "Error:
	Example \"${example_name}\" does not exist!!!
  Full path: \"${EXAMPLE_PATH}\"
	"
  exit 1
fi

echo "Running example \"${example_name}\" - changing directory to \"${EXAMPLE_PATH}\""
cd ${EXAMPLE_PATH}

##############################################################
# Validate option
##############################################################
option_arg=$2
declare -a option_arr=()
option_arr+=("--apply-only" "--destroy-only")

if [[ $option_arg != "" ]]; then
    match=0
    for option in "${option_arr[@]}"; do
        echo "****** $option_arg , "
        if [[ $option == "$option_arg" ]]; then
            match=1
            break
        fi
    done
    if [[ $match = 0 ]]; then
      	echo "Error:
      	Unsupported option!!!
      	"
              runexample::usage
      	exit 1
    fi
fi

##############################################################
# Validate environment variables
##############################################################

## declare an array with all required environment variables
declare -a env_arr=()
declare -a undefined_env_arr=()

## User must define the token for OCM
env_arr+=("RHCS_TOKEN" "TF_VAR_cluster_name")

## For shared VPC scenario, user must provide the shared VPC AWS account details
## Make sure that all shared VPC examples names include "shared-vpc" substring
if [[ "${example_name}" == *"shared-vpc"* ]]; then
  echo "Running example with \"shared-vpc\""
  env_arr+=("TF_VAR_shared_vpc_aws_access_key_id" "TF_VAR_shared_vpc_aws_secret_access_key" "TF_VAR_shared_vpc_aws_region")
fi

## now loop through the above array
echo "Verify environment variable defined:"
NEWLINE=$'\n'
for env_name in "${env_arr[@]}"
do
  echo "  # ${env_name}=${!env_name}"
  if [[ -z "${!env_name}" ]]; then
    undefined_env_arr+=("${env_name}")
  fi
done

if [[ ${#undefined_env_arr[@]} > 0 ]]; then
	echo "Error:
  The following environment variables are not defined!!!"
    for undefined_env in "${undefined_env_arr[@]}"
    do
      echo "    # ${undefined_env}"
    done
  exit 1
fi

##############################################################
# terraform init
##############################################################

echo "Cleaning Terraform files ..."
rm -rf .terraform .terraform.lock.hcl
echo "Cleaning Terraform files completed"

echo "Running \"terraform init\" ..."
terraform init
echo "\"terraform init\" completed"

##############################################################
# terraform apply
##############################################################
set +e
_apply_failed=false
    
if [[ $option_arg == "--destroy-only" ]]; then
    echo "destroy-only option was provided - skip apply"
else
    echo "Running \"terraform apply\" ..."
    terraform apply -auto-approve || _apply_failed=true
    if [ $_apply_failed == true ]
    then
        echo "\"terraform apply\" failed"
    else
        echo "\"terraform apply\" completed"
    fi
fi

##############################################################
# terraform destroy
##############################################################
set -e

if [[ $option_arg == "--apply-only" ]]; then
    echo "apply-only option was provided - skip destroy"
else
    echo "Running \"terraform destroy\" ..."
    terraform destroy -auto-approve
    echo "\"terraform destroy\" completed"
fi

##############################################################
# Handle "terraform apply" failure
##############################################################
if [ $_apply_failed == true ]
then
	echo "Error:
	terraform apply was failed!!!
	"
  exit 2
fi
