#!/bin/bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_EXAMPLE="${SCRIPT_DIR}/run-example.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ALL_EXAMPLES=(
    "ocm-role"
    "rosa-hcp-public"
    "rosa-hcp-public-unmanaged-oidc"
    "rosa-hcp-public-with-multiple-machinepools-and-idps"
    "rosa-hcp-public-with-sts-external-id"
    "rosa-hcp-private"
    "rosa-hcp-private-with-additional-control-plane-security-groups"
    "rosa-hcp-private-shared-vpc"
)

function usage() {
    cat <<EOF
Usage:
    ./run-all-examples.sh [options]

Options:
    --apply-only              Run terraform apply only (skip destroy)
    --destroy-only            Run terraform destroy only (skip apply)
    --dry-run                 Validate prerequisites without running terraform
    --include <example,...>   Run only the specified examples (comma-separated)
    --exclude <example,...>   Skip the specified examples (comma-separated)
    --sequential              Run examples one at a time (default)
    --stop-on-failure         Stop running after the first failure (default: continue)
    --cluster-prefix <pfx>   Prefix for cluster names (default: "test")
                              Each cluster gets: <prefix>-<short-example-name>
    --help                    Show this help message

Available examples:
$(printf '    - %s\n' "${ALL_EXAMPLES[@]}")

Environment variables (required):
    RHCS_TOKEN                          OCM API token

Environment variables (shared-vpc only — one auth method per account):
    TF_VAR_network_owner_aws_access_key_id      Network-owner AWS access key
    TF_VAR_network_owner_aws_secret_access_key   Network-owner AWS secret key
      OR
    TF_VAR_network_owner_aws_profile             Network-owner AWS profile name

    TF_VAR_cluster_owner_aws_access_key_id       Cluster-owner AWS access key
    TF_VAR_cluster_owner_aws_secret_access_key   Cluster-owner AWS secret key
      OR
    TF_VAR_cluster_owner_aws_profile             Cluster-owner AWS profile name

    For backwards compatibility with run-example.sh, these also work:
    TF_VAR_shared_vpc_aws_access_key_id
    TF_VAR_shared_vpc_aws_secret_access_key
    TF_VAR_shared_vpc_aws_region

Examples:
    # Run all examples
    ./run-all-examples.sh --cluster-prefix mytest

    # Run only public examples
    ./run-all-examples.sh --include rosa-hcp-public,rosa-hcp-public-unmanaged-oidc

    # Run everything except shared-vpc
    ./run-all-examples.sh --exclude rosa-hcp-private-shared-vpc

    # Dry-run to check prerequisites
    ./run-all-examples.sh --dry-run
EOF
}

declare -a INCLUDE_LIST=()
declare -a EXCLUDE_LIST=()
OPTION_ARG=""
DRY_RUN=false
STOP_ON_FAILURE=false
CLUSTER_PREFIX="test"

function require_option_value() {
    local option="$1"
    local value="${2:-}"

    if [[ -z "$value" || "$value" == --* ]]; then
        echo -e "${RED}Error: Option '${option}' requires a value${NC}"
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply-only)
            OPTION_ARG="--apply-only"
            shift
            ;;
        --destroy-only)
            OPTION_ARG="--destroy-only"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --include)
            require_option_value "$1" "${2:-}"
            IFS=',' read -ra INCLUDE_LIST <<< "$2"
            shift 2
            ;;
        --exclude)
            require_option_value "$1" "${2:-}"
            IFS=',' read -ra EXCLUDE_LIST <<< "$2"
            shift 2
            ;;
        --sequential)
            shift
            ;;
        --stop-on-failure)
            STOP_ON_FAILURE=true
            shift
            ;;
        --cluster-prefix)
            require_option_value "$1" "${2:-}"
            CLUSTER_PREFIX="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            usage
            exit 1
            ;;
    esac
done

#######################################
# Build the list of examples to run
#######################################
declare -a EXAMPLES_TO_RUN=()

if [[ ${#INCLUDE_LIST[@]} -gt 0 ]]; then
    for ex in "${INCLUDE_LIST[@]}"; do
        valid_example=false
        for available_example in "${ALL_EXAMPLES[@]}"; do
            if [[ "$available_example" == "$ex" ]]; then
                valid_example=true
                break
            fi
        done
        if [[ "$valid_example" == false ]]; then
            echo -e "${RED}Error: Example '${ex}' is not an available example${NC}"
            exit 1
        fi
        EXAMPLES_TO_RUN+=("$ex")
    done
else
    EXAMPLES_TO_RUN=("${ALL_EXAMPLES[@]}")
fi

if [[ ${#EXCLUDE_LIST[@]} -gt 0 ]]; then
    declare -a FILTERED=()
    for ex in "${EXAMPLES_TO_RUN[@]}"; do
        skip=false
        for excl in "${EXCLUDE_LIST[@]}"; do
            if [[ "$ex" == "$excl" ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == false ]]; then
            FILTERED+=("$ex")
        fi
    done
    EXAMPLES_TO_RUN=("${FILTERED[@]}")
fi

if [[ ${#EXAMPLES_TO_RUN[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No examples to run after filtering${NC}"
    exit 1
fi

#######################################
# Map example name to a short suffix for cluster naming
#######################################
function short_name() {
    case "$1" in
        ocm-role)                                                   echo "ocm" ;;
        rosa-hcp-public)                                            echo "pub" ;;
        rosa-hcp-public-unmanaged-oidc)                             echo "pub-oidc" ;;
        rosa-hcp-public-with-multiple-machinepools-and-idps)        echo "pub-multi" ;;
        rosa-hcp-public-with-sts-external-id)                       echo "pub-extid" ;;
        rosa-hcp-private)                                           echo "priv" ;;
        rosa-hcp-private-with-additional-control-plane-security-groups) echo "priv-sg" ;;
        rosa-hcp-private-shared-vpc)                                echo "priv-svpc" ;;
        *) echo "${1:0:10}" ;;
    esac
}

#######################################
# Validate prerequisites for an example
# Returns 0 if OK, 1 if missing requirements
#######################################
function validate_example() {
    local example="$1"
    local errors=0

    echo -e "  ${CYAN}Checking: ${example}${NC}"

    # All examples need RHCS_TOKEN
    if [[ -z "${RHCS_TOKEN:-}" ]]; then
        echo -e "    ${RED}MISSING: RHCS_TOKEN${NC}"
        ((errors++))
    else
        echo -e "    ${GREEN}OK: RHCS_TOKEN${NC}"
    fi

    # All cluster examples need TF_VAR_cluster_name (set dynamically, so just check AWS)
    if [[ "$example" != "ocm-role" && "$example" != *"shared-vpc"* ]]; then
        # Check AWS credentials are available
        if ! aws sts get-caller-identity &>/dev/null; then
            echo -e "    ${RED}MISSING: AWS credentials (aws sts get-caller-identity failed)${NC}"
            ((errors++))
        else
            echo -e "    ${GREEN}OK: AWS credentials${NC}"
        fi
    fi

    # Shared VPC needs two AWS accounts
    if [[ "$example" == *"shared-vpc"* ]]; then
        local has_network_owner=false
        local has_cluster_owner=false

        # Network owner: access key pair OR profile
        if [[ -n "${TF_VAR_network_owner_aws_access_key_id:-}" && -n "${TF_VAR_network_owner_aws_secret_access_key:-}" ]]; then
            has_network_owner=true
        elif [[ -n "${TF_VAR_network_owner_aws_profile:-}" ]]; then
            has_network_owner=true
        # Backwards compat with run-example.sh env var names
        elif [[ -n "${TF_VAR_shared_vpc_aws_access_key_id:-}" && -n "${TF_VAR_shared_vpc_aws_secret_access_key:-}" ]]; then
            has_network_owner=true
            export TF_VAR_network_owner_aws_access_key_id="${TF_VAR_shared_vpc_aws_access_key_id}"
            export TF_VAR_network_owner_aws_secret_access_key="${TF_VAR_shared_vpc_aws_secret_access_key}"
        fi

        if [[ "$has_network_owner" == true ]]; then
            echo -e "    ${GREEN}OK: Network-owner AWS credentials${NC}"
        else
            echo -e "    ${RED}MISSING: Network-owner AWS credentials${NC}"
            echo -e "    ${YELLOW}  Set TF_VAR_network_owner_aws_access_key_id + TF_VAR_network_owner_aws_secret_access_key${NC}"
            echo -e "    ${YELLOW}  OR TF_VAR_network_owner_aws_profile${NC}"
            ((errors++))
        fi

        # Cluster owner: access key pair OR profile
        if [[ -n "${TF_VAR_cluster_owner_aws_access_key_id:-}" && -n "${TF_VAR_cluster_owner_aws_secret_access_key:-}" ]]; then
            has_cluster_owner=true
        elif [[ -n "${TF_VAR_cluster_owner_aws_profile:-}" ]]; then
            has_cluster_owner=true
        fi

        if [[ "$has_cluster_owner" == true ]]; then
            echo -e "    ${GREEN}OK: Cluster-owner AWS credentials${NC}"
        else
            echo -e "    ${RED}MISSING: Cluster-owner AWS credentials${NC}"
            echo -e "    ${YELLOW}  Set TF_VAR_cluster_owner_aws_access_key_id + TF_VAR_cluster_owner_aws_secret_access_key${NC}"
            echo -e "    ${YELLOW}  OR TF_VAR_cluster_owner_aws_profile${NC}"
            ((errors++))
        fi
    fi

    return $errors
}

#######################################
# Print run plan
#######################################
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  ROSA HCP Examples Runner${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo -e "${CYAN}Examples to run (${#EXAMPLES_TO_RUN[@]}):${NC}"
for ex in "${EXAMPLES_TO_RUN[@]}"; do
    if [[ "$ex" == "ocm-role" ]]; then
        echo -e "  - ${ex} ${YELLOW}(IAM role only, no cluster)${NC}"
    elif [[ "$ex" == *"shared-vpc"* ]]; then
        echo -e "  - ${ex} ${YELLOW}(requires 2 AWS accounts)${NC}"
    else
        cluster="${CLUSTER_PREFIX}-$(short_name "$ex")"
        echo -e "  - ${ex} ${YELLOW}(cluster: ${cluster})${NC}"
    fi
done
echo ""

if [[ -n "$OPTION_ARG" ]]; then
    echo -e "${CYAN}Mode: ${OPTION_ARG}${NC}"
else
    echo -e "${CYAN}Mode: apply + destroy${NC}"
fi
echo ""

#######################################
# Validate all prerequisites
#######################################
echo -e "${BOLD}Validating prerequisites...${NC}"
validation_failed=false
declare -a SKIPPED_EXAMPLES=()

for ex in "${EXAMPLES_TO_RUN[@]}"; do
    if ! validate_example "$ex"; then
        if [[ "$DRY_RUN" == true || "$STOP_ON_FAILURE" == true ]]; then
            validation_failed=true
        else
            echo -e "  ${YELLOW}WARNING: Skipping '${ex}' due to missing prerequisites${NC}"
            SKIPPED_EXAMPLES+=("$ex")
        fi
    fi
done
echo ""

if [[ "$validation_failed" == true ]]; then
    echo -e "${RED}Prerequisite validation failed. Fix the issues above and retry.${NC}"
    exit 1
fi

# Remove skipped examples
if [[ ${#SKIPPED_EXAMPLES[@]} -gt 0 ]]; then
    declare -a VALID_EXAMPLES=()
    for ex in "${EXAMPLES_TO_RUN[@]}"; do
        skip=false
        for skipped in "${SKIPPED_EXAMPLES[@]}"; do
            if [[ "$ex" == "$skipped" ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == false ]]; then
            VALID_EXAMPLES+=("$ex")
        fi
    done
    EXAMPLES_TO_RUN=("${VALID_EXAMPLES[@]}")
fi

if [[ ${#EXAMPLES_TO_RUN[@]} -eq 0 ]]; then
    echo -e "${RED}No examples remain after prerequisite validation${NC}"
    exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${GREEN}Dry run complete. All prerequisites validated for ${#EXAMPLES_TO_RUN[@]} example(s).${NC}"
    exit 0
fi

#######################################
# Run examples
#######################################
declare -A RESULTS=()
total=${#EXAMPLES_TO_RUN[@]}
current=0

for example in "${EXAMPLES_TO_RUN[@]}"; do
    (( ++current ))
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}  [${current}/${total}] Running: ${example}${NC}"
    echo -e "${BOLD}========================================${NC}"

    # Set cluster name per example (ocm-role doesn't need one but it's harmless)
    cluster_name="${CLUSTER_PREFIX}-$(short_name "$example")"
    export TF_VAR_cluster_name="${cluster_name}"

    start_time=$(date +%s)

    set +e
    (cd "${REPO_ROOT}" && "${RUN_EXAMPLE}" "${example}" ${OPTION_ARG})
    exit_code=$?
    set -e

    end_time=$(date +%s)
    duration=$(( end_time - start_time ))
    duration_min=$(( duration / 60 ))
    duration_sec=$(( duration % 60 ))

    if [[ $exit_code -eq 0 ]]; then
        RESULTS["$example"]="PASS (${duration_min}m ${duration_sec}s)"
        echo -e "${GREEN}[${current}/${total}] ${example}: PASSED (${duration_min}m ${duration_sec}s)${NC}"
    else
        RESULTS["$example"]="FAIL (exit ${exit_code}, ${duration_min}m ${duration_sec}s)"
        echo -e "${RED}[${current}/${total}] ${example}: FAILED (exit ${exit_code}, ${duration_min}m ${duration_sec}s)${NC}"

        if [[ "$STOP_ON_FAILURE" == true ]]; then
            echo -e "${RED}Stopping due to --stop-on-failure${NC}"
            break
        fi
    fi
done

#######################################
# Summary
#######################################
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  Results Summary${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

pass_count=0
fail_count=0

for example in "${ALL_EXAMPLES[@]}"; do
    result="${RESULTS[$example]:-SKIPPED}"
    if [[ "$result" == PASS* ]]; then
        echo -e "  ${GREEN}PASS${NC}  ${example}  ${YELLOW}${result#PASS }${NC}"
        ((pass_count++))
    elif [[ "$result" == FAIL* ]]; then
        echo -e "  ${RED}FAIL${NC}  ${example}  ${YELLOW}${result#FAIL }${NC}"
        ((fail_count++))
    elif [[ "$result" == "SKIPPED" ]]; then
        # Only show if it was in the original run list
        for sk in "${SKIPPED_EXAMPLES[@]:-}"; do
            if [[ "$sk" == "$example" ]]; then
                echo -e "  ${YELLOW}SKIP${NC}  ${example}"
                break
            fi
        done
    fi
done

echo ""
echo -e "${BOLD}Total: ${pass_count} passed, ${fail_count} failed, ${#SKIPPED_EXAMPLES[@]} skipped${NC}"
echo ""

if [[ $fail_count -gt 0 ]]; then
    exit 1
fi
