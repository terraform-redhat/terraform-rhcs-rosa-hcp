FROM registry.access.redhat.com/ubi9/ubi:latest
WORKDIR /app
COPY . /app
RUN yum update -y && yum install -y yum-utils shadow-utils unzip tar make && \
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo && \
    yum -y install terraform && \
    yum clean all && \
    rm -rf /var/cache/yum
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && rm awscliv2.zip && rm -r aws/
RUN curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz" -o "rosa.tar.gz" && \
    tar xfvz rosa.tar.gz --no-same-owner && mv rosa /usr/local/bin/rosa && rm rosa.tar.gz
# Added terraform-docs following the instructions here: https://terraform-docs.io/user-guide/installation/
RUN curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.17.0/terraform-docs-v0.17.0-$(uname)-amd64.tar.gz && \
    tar -xzf terraform-docs.tar.gz terraform-docs && chmod +x terraform-docs && \
    mv terraform-docs /usr/local/bin/terraform-docs && rm terraform-docs.tar.gz