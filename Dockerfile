# renovate: datasource=docker depName=registry.access.redhat.com/ubi9/ubi
FROM registry.access.redhat.com/ubi9/ubi:latest
WORKDIR /app
COPY . /app
RUN yum update -y && yum install -y yum-utils shadow-utils unzip tar make git python3-pip && \
    yum clean all && \
    rm -rf /var/cache/yum
# Prow / integration client image: newest Terraform (TERRAFORM_VERSION). Module minimum compatibility is checked in GitHub Actions verify-min-terraform.yml.
# renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver
ARG TERRAFORM_VERSION=1.15.4
RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    yum -y install "terraform-${TERRAFORM_VERSION}" && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    terraform version
# renovate: datasource=github-releases depName=aws/aws-cli versioning=semver-coerced
ARG AWS_CLI_VERSION=2.34.53
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf awscliv2.zip aws/ && \
    aws --version
# renovate: datasource=github-releases depName=openshift/rosa versioning=semver
ARG ROSA_VERSION=1.2.62
RUN curl -fsSL "https://mirror.openshift.com/pub/cgw/rosa/${ROSA_VERSION}/rosa-linux.tar.gz" -o rosa-linux.tar.gz && \
    tar -xzf rosa-linux.tar.gz --no-same-owner && mv rosa /usr/local/bin/rosa && \
    rm -f rosa-linux.tar.gz && \
    rosa version
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs versioning=semver
ARG TERRAFORM_DOCS_VERSION=0.24.0
RUN curl -fsSL "https://terraform-docs.io/dl/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz" -o terraform-docs.tar.gz && \
    tar -xzf terraform-docs.tar.gz terraform-docs && chmod +x terraform-docs && \
    mv terraform-docs /usr/local/bin/terraform-docs && rm terraform-docs.tar.gz
# OpenShift Prow: arbitrary UID runs with GID 0; group-writable /app for make pre-push-checks.
RUN mkdir -p /app/bin /app/.tflint.d/plugins && \
    chgrp -R 0 /app && \
    chmod -R g+rwX /app
ENV PATH="/usr/local/bin:${PATH}" \
    HOME="/app"
