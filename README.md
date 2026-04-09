# TechCorp Terraform Infrastructure

## Prerequisites

- AWS Account
- Terraform installed
- AWS CLI configured

## Deployment Steps

1. Initialize Terraform

terraform init

2. Preview infrastructure

terraform plan

3. Apply configuration

terraform apply

Type yes when prompted.

## Verification

- Check AWS Console
- Confirm VPC created
- Confirm EC2 instances running
- Access Load Balancer DNS

## Destroy Infrastructure

terraform destroy
