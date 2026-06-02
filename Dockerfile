# Pin UBI minor release; avoid :latest for reproducible CI image builds (Prow builds this Dockerfile).
# renovate: datasource=docker depName=registry.access.redhat.com/ubi9/ubi-minimal versioning=regex:^(?<major>\d+)\.(?<minor>\d+)$
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8
WORKDIR /app
COPY . /app
# curl-minimal is preinstalled; do not install the curl RPM (conflicts with curl-minimal).
RUN microdnf install -y tar gzip unzip make git which shadow-utils gnupg2 && \
    microdnf clean all
# Prow / integration client image: newest Terraform (TERRAFORM_VERSION). Module minimum compatibility is checked in GitHub Actions verify-min-terraform.yml.
# renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver
ARG TERRAFORM_VERSION=1.15.5
RUN curl -fsSL -o /etc/yum.repos.d/hashicorp.repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    microdnf install -y "terraform-${TERRAFORM_VERSION}" && \
    microdnf clean all && \
    terraform version
# renovate: datasource=github-releases depName=aws/aws-cli versioning=semver-coerced
ARG AWS_CLI_VERSION=2.34.53
# PGP verify per https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
RUN set -euo pipefail; \
    aws_zip="awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip"; \
    curl -fsSL "https://awscli.amazonaws.com/${aws_zip}" -o awscliv2.zip; \
    curl -fsSL "https://awscli.amazonaws.com/${aws_zip}.sig" -o awscliv2.sig; \
    gpg --import /app/hack/aws-cli-public-key.asc; \
    gpg --verify awscliv2.sig awscliv2.zip; \
    unzip awscliv2.zip; \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin; \
    rm -rf awscliv2.zip awscliv2.sig aws/; \
    aws --version
# renovate: datasource=github-releases depName=openshift/rosa versioning=semver
ARG ROSA_VERSION=1.2.63
# SHA256 from mirror sha256sum.txt (https://mirror.openshift.com/pub/cgw/rosa/<version>/)
RUN set -euo pipefail; \
    rosa_mirror="https://mirror.openshift.com/pub/cgw/rosa/${ROSA_VERSION}"; \
    curl -fsSL "${rosa_mirror}/rosa-linux.tar.gz" -o rosa-linux.tar.gz; \
    curl -fsSL "${rosa_mirror}/sha256sum.txt" -o sha256sum.txt; \
    grep -F ' rosa-linux.tar.gz' sha256sum.txt | sha256sum -c -; \
    tar xzf rosa-linux.tar.gz && mv rosa /usr/local/bin/rosa; \
    rm -f rosa-linux.tar.gz sha256sum.txt; \
    rosa version
# Tool versions: Makefile (make tools).
RUN make tools
ENV PATH="/app/bin:/usr/local/bin:${PATH}" \
    HOME="/app"
# Run as root (default): Prow/ci-operator mounts the repo workspace with root-owned files; non-root USER breaks make verify / verify-gen writes.
