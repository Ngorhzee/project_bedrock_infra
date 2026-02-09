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
  
  # To attach an existing vpc to cluster
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
    amazon-cloudwatch-observability = {
      
    }
  }
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
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

