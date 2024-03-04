variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the EKS cluster will be deployed."
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
  default     = "development"
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes version for the EKS cluster."
  default     = "1.27"
}

# variable "private_subnet_ids" {
#   type        = list(string)
#   description = "A list of IDs of private subnets where worker nodes will be deployed."
# }

# variable "control_plane_subnet_ids" {
#   type        = list(string)
#   description = "A list of IDs of subnets where the EKS control plane will be deployed."
# }

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of IDs of public subnets for load balancers and other public resources."
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "A list of CIDR blocks allowed to access the Kubernetes API server."
}

variable "tags" {
  type        = map(any)
  description = "Additional tags to apply to AWS resources."
  default = {
    Environment = "DEVELOPMENT"
  }
}
