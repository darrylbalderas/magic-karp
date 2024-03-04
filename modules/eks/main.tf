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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# data "aws_availability_zones" "available" {}
# data "aws_caller_identity" "current" {}
# data "aws_ecrpublic_authorization_token" "token" {}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# data "aws_ami" "eks_default" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-${var.cluster_version}-v*"]
#   }
# }


data "aws_ami" "eks_default_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-arm64-node-${var.cluster_version}-v*"]
  }
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
      # preserve    = true
      # timeouts = {
      #   create = "25m"
      #   delete = "10m"
      # }
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
      node_group_name                 = "managed-ondemand-karpenter"
      instance_types                  = ["t4g.small"]
      create_security_group           = false
      subnet_ids                      = var.public_subnet_ids
      max_size                        = 2
      desired_size                    = 2
      min_size                        = 1
      ami_id                          = data.aws_ami.eks_default_arm.id
      launch_template_name            = "managed-karpenter-node-group"
      launch_template_use_name_prefix = true
      launch_template_description     = "Managed node group karpenter launch template"
      ebs_optimized                   = true
      enable_monitoring               = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      iam_role_arn         = module.karpenter.node_iam_role_arn
      launch_template_tags = merge({}, local.cluster_tags)
      timeouts = {
        create = "20m"
        update = "20m"
        delete = "20m"
      }
      tags = {}

      labels = {
        Environment = "DEVELOPMENT"
      }
    }
  }

  tags = merge(local.tags, local.cluster_tags)
}
