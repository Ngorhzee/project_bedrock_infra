variable "private_subnet_ids" {
  description = "List of private subnets"
  type        = list(string)
}

variable "eks_security_group_id" {
    description = "Security group ID for EKS cluster"
    
}

variable "vpc_id" {
    description = "vpc_id"
    type        = string
  
}

variable "oidc_provider" {
  description = "The OIDC provider URL for the EKS cluster"
}