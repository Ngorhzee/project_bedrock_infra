output "cluster_endpoint" {
  value = module.eks.cluster_endpoint

}

output "cluster_name" {
  value = module.eks.cluster_name

}

output "region" {
  value = "us-east-1"
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "assets_bucket_name" {
  value = module.storage.bucket_name

}

output "catalog_mysql_endpoint" {
  description = "Catalog MySQL RDS endpoint"
  value       = module.database.catalog_mysql_endpoint
  sensitive   = true
}

output "catalog_mysql_secret_arn" {
  description = "ARN of Catalog MySQL credentials in Secrets Manager"
  value       = module.database.catalog_mysql_secret_arn
}

output "orders_postgresql_endpoint" {
  description = "Orders PostgreSQL RDS endpoint"
  value       = module.database.orders_postgresql_endpoint
  sensitive   = true
}

output "orders_postgresql_secret_arn" {
  description = "ARN of Orders PostgreSQL credentials in Secrets Manager"
  value       = module.database.orders_postgresql_secret_arn
}