#!/bin/sh
set -eux

# Check for dependencies
if ! command -v sshuttle >/dev/null; then
    echo "Please install sshuttle"
    exit 1
fi
if ! command -v jq >/dev/null; then
    echo "Please install jq"
    exit 1
fi

# Assigns public IP of bastion host to variables
BASTION_HOST_PUB_IP=$(terraform output -json | jq '.bastion_host_public_ip.value[0]' -r)
# Sest bastion host ssh .pem filename to variable
ROSA_KEY=$(find . | grep '.pem')
# Get console URL of Rosa cluster
CONSOLE=$(terraform output -json | jq '.cluster_console_url.value' -r)
# Get API url of Rosa Cluster
API=$(terraform output -json | jq '.cluster_api_url.value' -r)

if [ -z "$API" ]; then
    echo "Could not find the API URL"
    exit 4
fi
if [ -z "$CONSOLE" ]; then
    echo "Could not find the console URL"
    exit 4
fi
if [ -z "$ROSA_KEY" ]; then
    echo "Could not find the SSH key"
    exit 4
fi
if [ -z "$BASTION_HOST_PUB_IP" ]; then
    echo "Could not find the SSH bastion host IP address"
    exit 4
fi

# Output some useful info
echo "Console URL: ${CONSOLE}"
echo "API URL: ${API}"

# Connect to the SSH bastion
# Note that the user depends on AMI and might require to be changed
sshuttle --ssh-cmd "ssh -i ${TF_DIR:-.}/${ROSA_KEY}" --dns -NHr "ubuntu@${BASTION_HOST_PUB_IP}" 10.0.0.0/16
