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

TERRAFORM_JSON=$(terraform output -json)
# Assigns public IP of bastion host to variables
BASTION_HOST_PUB_IP=$(jq '.bastion_host_public_ip.value[0]' -r <<< $TERRAFORM_JSON)
# Sest bastion host ssh .pem filename to variable
ROSA_KEY=$(find . | grep '.pem')
# Get API url of Rosa Cluster
API=$(jq '.cluster_api_url.value' -r <<< $TERRAFORM_JSON)
PW=$(jq '.password.value.result' -r <<< $TERRAFORM_JSON)

if [ -z "$API" ]; then
    echo "Could not find the API URL"
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
if [ -z "$PW" ]; then
    echo "Could not find the cluster idp password"
    exit 4
fi

# Connect to the SSH bastion
# Note that the user depends on AMI and might require to be changed
sshuttle --daemon --pidfile="${TF_DIR:-.}/sshuttle-pid-file" --ssh-cmd "ssh -i ${TF_DIR:-.}/${ROSA_KEY}" --dns -NHr "ec2-user@${BASTION_HOST_PUB_IP}" 10.0.0.0/16
oc login $API --username admin --password "${PW}"