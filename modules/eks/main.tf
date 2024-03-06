locals {
  tags = merge({
    Application = var.cluster_name
    }, var.tags
  )

  # NOTE - if creating multiple security groups with this module, only tag the
  # security group that Karpenter should utilize with the following tag
  # (i.e. - at most, only one security group should have this tag in your account)
  cluster_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr_public
}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 20.0"
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  enable_irsa                     = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  vpc_id                               = var.vpc_id
  subnet_ids                           = var.public_subnet_ids
  control_plane_subnet_ids             = var.public_subnet_ids
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  create_cloudwatch_log_group              = true
  create_cluster_security_group            = true
  create_node_security_group               = true
  enable_cluster_creator_admin_permissions = true

  cluster_security_group_tags = {}
  node_security_group_tags    = {}

  eks_managed_node_groups = {
    karpenter = {
      node_group_name        = "managed-ondemand-karpenter"
      instance_types         = ["t3.small"]
      create_security_group  = false
      subnet_ids             = var.public_subnet_ids
      max_size               = 2
      desired_size           = 2
      min_size               = 2
      create_launch_template = true
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        Karpenter                          = aws_iam_policy.karpenter.arn
      }
      timeouts = {
        create = "11m"
        update = "11m"
        delete = "11m"
      }
      tags = {}

      labels = {
        Environment = "DEVELOPMENT"
      }
    }
  }

  tags = merge(local.tags, local.cluster_tags)
}
