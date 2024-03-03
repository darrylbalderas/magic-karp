#!/bin/bash

# Terraform

terraform fmt -recursive
terraform validate


# Security

gitleaks detect --source . -v