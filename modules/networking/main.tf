locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = merge({
    Application = var.vpc_name
  }, var.tags)
}

data "aws_availability_zones" "available" {}
# data "aws_caller_identity" "current" {}

# More information about module https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]


  public_subnet_tags = merge({
    "kubernetes.io/role/elb" = 1
    },
    var.vpc_private_subnet_tags
  )

  private_subnet_tags = merge(
    {
      "kubernetes.io/role/internal-elb" = 1
    },
    var.vpc_public_subnet_tags
  )

  tags = local.tags
}
