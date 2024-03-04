#!/bin/bash

# Terraform

terraform fmt -recursive
terraform validate
tflint  --recursive

# Security

gitleaks detect --source . -v
