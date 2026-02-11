output "catalog_mysql_endpoint" {
  description = "Catalog MySQL RDS endpoint"
  value       = aws_db_instance.catalog_service.endpoint
  sensitive   = true
}

output "catalog_mysql_secret_arn" {
  description = "ARN of Catalog MySQL credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.catalog_mysql_credentials.arn
}

output "orders_postgresql_endpoint" {
  description = "Orders PostgreSQL RDS endpoint"
  value       = aws_db_instance.orders_service.endpoint
  sensitive   = true
}

output "orders_postgresql_secret_arn" {
  description = "ARN of Orders PostgreSQL credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.orders_postgresql_credentials.arn
}