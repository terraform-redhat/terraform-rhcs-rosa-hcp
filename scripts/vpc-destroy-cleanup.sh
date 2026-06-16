#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

VPC_ID="${1:-}"

if [[ -z "$VPC_ID" ]]; then
  echo "usage: $0 <vpc-id>" >&2
  exit 1
fi

MAX_ATTEMPTS="${VPC_DESTROY_CLEANUP_MAX_ATTEMPTS:-12}"
INITIAL_BACKOFF_SECONDS="${VPC_DESTROY_CLEANUP_INITIAL_BACKOFF_SECONDS:-10}"
MAX_BACKOFF_SECONDS="${VPC_DESTROY_CLEANUP_MAX_BACKOFF_SECONDS:-60}"

VPCE_ROUTER_SG_QUERY="SecurityGroups[?GroupName!=\`default\` && contains(GroupName, \`-vpce-private-router\`)].[GroupId,GroupName,Description]"
NON_VPCE_SG_QUERY="SecurityGroups[?GroupName!=\`default\` && !contains(GroupName, \`-vpce-private-router\`)].[GroupId,GroupName,Description]"

count_vpce_private_router_sgs() {
  aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query "length(${VPCE_ROUTER_SG_QUERY})" \
    --output text
}

delete_detached_vpce_router_sgs() {
  while IFS=$'\t' read -r sg_id sg_name _sg_desc; do
    [[ -z "$sg_id" || "$sg_id" == "None" ]] && continue

    attached_enis="$(aws ec2 describe-network-interfaces \
      --filters "Name=group-id,Values=${sg_id}" \
      --query 'length(NetworkInterfaces)' \
      --output text)"

    if [[ "$attached_enis" != "0" ]]; then
      continue
    fi

    if ! aws ec2 delete-security-group --group-id "$sg_id"; then
      echo "Warning: failed to delete security group ${sg_id} (${sg_name})" >&2
    fi
  done < <(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query "${VPCE_ROUTER_SG_QUERY}" \
    --output text)
}

attempt=1
backoff="$INITIAL_BACKOFF_SECONDS"

while [[ "$attempt" -le "$MAX_ATTEMPTS" ]]; do
  delete_detached_vpce_router_sgs

  remaining_vpce="$(count_vpce_private_router_sgs)"
  if [[ "$remaining_vpce" == "0" ]]; then
    other_count="$(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=${VPC_ID}" \
      --query "length(${NON_VPCE_SG_QUERY})" \
      --output text)"

    if [[ "$other_count" != "0" ]]; then
      echo "Warning: VPC ${VPC_ID} has ${other_count} non-default security group(s) outside *-vpce-private-router cleanup scope." >&2
      aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --query "${NON_VPCE_SG_QUERY}" \
        --output table >&2
    fi
    exit 0
  fi

  if [[ "$attempt" -eq "$MAX_ATTEMPTS" ]]; then
    break
  fi

  echo "VPC ${VPC_ID} still has ${remaining_vpce} *-vpce-private-router security group(s); retrying in ${backoff}s (attempt ${attempt}/${MAX_ATTEMPTS})..." >&2
  sleep "$backoff"
  backoff=$((backoff * 2))
  if [[ "$backoff" -gt "$MAX_BACKOFF_SECONDS" ]]; then
    backoff="$MAX_BACKOFF_SECONDS"
  fi
  attempt=$((attempt + 1))
done

echo "VPC ${VPC_ID} still has ${remaining_vpce} *-vpce-private-router security group(s) after cleanup." >&2
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query "${VPCE_ROUTER_SG_QUERY}" \
  --output table >&2
exit 1
