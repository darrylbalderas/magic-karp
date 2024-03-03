variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "vpc_private_subnet_tags" {
  type = map(any)
  default = {
    "karpenter.sh/discovery"          = "default"
    "kubernetes.io/cluster/default"   = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

variable "vpc_public_subnet_tags" {
  type = map(any)
  default = {
    "karpenter.sh/discovery" = "default"
    "kubernetes.io/role/elb" = 1
  }
}

variable "tags" {
  type = map(string)
  default = {
    "Environment" = "DEVELOPMENT"
  }
}