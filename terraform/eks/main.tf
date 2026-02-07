# resource "aws_eks_cluster" "eks_cluster" {
#     name = "project-bedrock-cluster"
#     access_config {
#       authentication_mode = "API"
#     }
#     version = "1.31"
#     bootstrap_self_managed_addons = false
#     vpc_config {
#     endpoint_private_access = true
#     endpoint_public_access  = true
#       subnet_ids = var.private_subnets_id

#     }
    
#     compute_config {
#     enabled       = true
#     node_pools    = ["general-purpose"]
#     node_role_arn = aws_iam_role.eks_node.arn
#   }
#     kubernetes_network_config {
#       elastic_load_balancing {
#         enabled = true
#       }
      
#     }
#     storage_config {
#     block_storage {
#       enabled = true
#     }
#     }
#     role_arn = aws_iam_role.cluster_iam_role.arn
#     depends_on = [ 
#       aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
#       aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryPullOnly,
#       aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodeMinimalPolicy, 
#       aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy, 
#       aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy, ]
#   tags = {
#     Project = "Bedrock"
#     Terraform   = "true"
#   }

# }
module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  name = "project-bedrock-cluster"
  kubernetes_version = "1.33"
  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  control_plane_scaling_config = {
    tier = "standard"
  }
  vpc_id = var.vpc_id
  subnet_ids = var.private_subnets_id
    addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }
   eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
  tags = {
    Project = "Bedrock"
    Terraform   = "true"
  }
  compute_config = {
    enabled       = true
    node_pools    = ["general-purpose"]

  }


}


resource "aws_iam_role" "eks_node" {
  name = "project-bedrock-node-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

