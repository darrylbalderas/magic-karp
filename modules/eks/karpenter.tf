resource "aws_iam_policy" "karpenter" {
  name        = "${var.cluster_name}-karpenter"
  description = "Karpenter Usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = merge(local.tags, local.cluster_tags)
}

# More info https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/karpenter
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  enable_spot_termination         = true

  create_iam_role         = true
  create_node_iam_role    = true
  create_instance_profile = true

  iam_role_use_name_prefix = false
  iam_role_description     = "Karpenter IAM role"

  node_iam_role_use_name_prefix = false
  node_iam_role_description     = "Karpenter Node IAM role"
  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    Karpenter                          = aws_iam_policy.karpenter.arn
  }

  tags = merge(local.tags, {})
}
