#!/usr/bin/env bash

set -xe

if [[ -n "$(git status --porcelain | grep -v "Dockerfile")" ]]; then
    echo "It seems like you need to run 'make terraform-docs'. Please run it and commit the changes"
    git status --porcelain | grep -v "Dockerfile"
    exit 1
fi
