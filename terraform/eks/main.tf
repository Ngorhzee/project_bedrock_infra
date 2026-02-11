module "eks_cluster" {
  source                 = "terraform-aws-modules/eks/aws"
  version                = "~> 21.0"
  name                   = "project-bedrock-cluster"
  kubernetes_version     = "1.34"
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  control_plane_scaling_config = {
    tier = "standard"
  }

  # To attach an existing vpc to cluster
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_id
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }


  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {
    general = {
      name = "general"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      disk_size = 20

      labels = {
        role = "general"
      }
      iam_role_additional_policies = {
        CloudWatchAgent = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      tags = {
         Project = "barakat-2025-capstone"
        Terraform = "true"
      }

    }
  }
  tags = {
    Project = "barakat-2025-capstone"
    Terraform = "true"
  }
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]

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
  tags = {
     Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_eks_access_entry" "iam_user" {
  cluster_name  = module.eks_cluster.cluster_name
  principal_arn = "arn:aws:iam::651706736165:user/bedrock-dev-view"
  type          = "STANDARD"
  tags = {
     Project = "barakat-2025-capstone"
  }
}

resource "aws_eks_access_policy_association" "iam_user" {
  cluster_name  = module.eks_cluster.cluster_name
  principal_arn = "arn:aws:iam::651706736165:user/bedrock-dev-view"
policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
     type       = "namespace"
    namespaces = ["retail-app"]
  }
}
