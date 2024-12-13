# Zero-Egress

## Introduction

This repository contains Terraform configurations to set up resources to allow a Disconnected AWS Virtual Private Cloud (VPC) for use with Red Hat OpenShift Service on AWS (ROSA) Hosted Control Planes (HCP) cluster. This setup ensures that all cluster traffic remains within the AWS network, eliminating the need for internet access (egress) for the cluster.


## Example Usage

```
module "zero_egress" {
  count       = var.is_zero_egress ? 1 : 0
  source      = "./zero-egress"
  vpc_id      = aws_vpc.vpc.id
  subnet_ids  = [for subnet in aws_subnet.private_subnet[*] : subnet.id]
  cidr_blocks = [for subnet in aws_subnet.private_subnet[*] : subnet.cidr_block]
}
```