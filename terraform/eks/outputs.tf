output "cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "eks_security_group_id" {
  value = module.eks_cluster.cluster_security_group_id
  
}

output "oidc_provider" {
  value = module.eks_cluster.oidc_provider
  
}