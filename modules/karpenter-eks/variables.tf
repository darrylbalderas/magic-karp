variable "cluster_endpoint_public_access_cidrs" {
  description = "A list of CIDR blocks allowed to access the Kubernetes API server."
  type        = list(string)
}
