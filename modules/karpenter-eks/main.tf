module "vpc" {
  source   = "../networking"
  vpc_name = "development"
  vpc_private_subnet_tags = {
    "karpenter.sh/discovery"            = "development"
    "kubernetes.io/cluster/development" = "shared"
  }
  vpc_public_subnet_tags = {
    "karpenter.sh/discovery" = "development"
  }
}

module "eks" {
  source                               = "../eks"
  vpc_id                               = module.vpc.vpc.vpc_id
  public_subnet_ids                    = module.vpc.vpc.public_subnets
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
}
