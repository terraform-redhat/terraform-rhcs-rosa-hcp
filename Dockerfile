# Pin UBI minor release; avoid :latest for reproducible CI image builds (Prow builds this Dockerfile).
# renovate: datasource=docker depName=registry.access.redhat.com/ubi9/ubi-minimal versioning=regex:^(?<major>\d+)\.(?<minor>\d+)$
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8
WORKDIR /app
COPY . /app
# curl-minimal is preinstalled; do not install the curl RPM (conflicts with curl-minimal).
RUN microdnf install -y tar gzip unzip make git which shadow-utils && \
    microdnf clean all
# Prow / integration client image: newest Terraform (TERRAFORM_VERSION). Module minimum compatibility is checked in GitHub Actions verify-min-terraform.yml.
# renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver
ARG TERRAFORM_VERSION=1.15.4
RUN curl -fsSL -o /etc/yum.repos.d/hashicorp.repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    microdnf install -y "terraform-${TERRAFORM_VERSION}" && \
    microdnf clean all && \
    terraform version
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf awscliv2.zip aws/
# renovate: datasource=github-releases depName=openshift/rosa versioning=semver
ARG ROSA_VERSION=1.2.62
RUN curl -fsSL "https://mirror.openshift.com/pub/cgw/rosa/${ROSA_VERSION}/rosa-linux.tar.gz" -o rosa.tar.gz && \
    tar xzf rosa.tar.gz && mv rosa /usr/local/bin/rosa && rm rosa.tar.gz
# Tool versions: Makefile (make tools).
RUN make tools
ENV PATH="/app/bin:/usr/local/bin:${PATH}" \
    HOME="/app"
# Run as root (default): Prow/ci-operator mounts the repo workspace with root-owned files; non-root USER breaks make verify / verify-gen writes.
