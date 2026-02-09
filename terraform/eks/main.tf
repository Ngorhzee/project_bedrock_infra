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
      most_recent = true
    }
  }
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  # Security group rules for the cluster
  # security_group_additional_rules = {
  #   ingress_nodes_ephemeral_ports = {
  #     description                = "Nodes on ephemeral ports"
  #     protocol                   = "tcp"
  #     from_port                  = 1025
  #     to_port                    = 65535
  #     type                       = "ingress"
  #     source_node_security_group = true
  #   }
    
  #   egress_all = {
  #     description = "Allow all egress"
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     type        = "egress"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  # }

  # # Security group rules for nodes
  # node_security_group_additional_rules = {
  #   # Allow nodes to communicate with each other
  #   ingress_self_all = {
  #     description = "Node to node all ports/protocols"
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     type        = "ingress"
  #     self        = true
  #   }

  #   # Allow LoadBalancer to access NodePorts
  #   ingress_nodeport_range = {
  #     description = "Allow access to NodePort range"
  #     protocol    = "tcp"
  #     from_port   = 30000
  #     to_port     = 32767
  #     type        = "ingress"
  #     cidr_blocks = ["0.0.0.0/0"]  # Or restrict to VPC CIDR
  #   }

  #   # Allow all egress
  #   egress_all = {
  #     description = "Node all egress"
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     type        = "egress"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }

  #   # Allow cluster control plane to access nodes
  #   ingress_cluster_443 = {
  #     description                   = "Cluster control plane to nodes"
  #     protocol                      = "tcp"
  #     from_port                     = 443
  #     to_port                       = 443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  # }
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

      tags = {
        Project   = "Bedrock"
        Terraform = "true"
      }
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

