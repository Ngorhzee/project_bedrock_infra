data "aws_caller_identity" "current" {
    
  
}
resource "aws_db_subnet_group" "subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
     Project = "barakat-2025-capstone"
  }

}

resource "aws_security_group" "catalog_db_sg" {
  name        = "catalog-db-sg"
  description = "Security group for catalog service database"
  vpc_id      = var.vpc_id

  ingress  {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    description     = "Allow MySQL access from EKS cluster"
    security_groups = [var.eks_security_group_id]
  }

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "catalog-mysql-sg"
    Project = "barakat-2025-capstone"

  }

}
resource "aws_security_group" "orders_db_sg" {
  name        = "orders-db-sg"
  description = "Security group for orders service database"
  vpc_id      = var.vpc_id

  ingress  {
    from_port       = 55432
    to_port         = 55432
    protocol        = "tcp"
    description     = "Allow PostgreSQL access from EKS cluster"
    security_groups = [var.eks_security_group_id]
  }

  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "orders-postgres-sg"
     Project = "barakat-2025-capstone"
  }

}

resource "random_password" "catalog_mysql" {
  length  = 16
  special = true

}

resource "random_password" "orders_postgres" {
  length  = 16
  special = true
}

resource "aws_db_instance" "catalog_service" {
  identifier                  = "project-bedrock-catalog-service-db"
  db_name                     = "catalogServicedb"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
   allocated_storage     = 20
  max_allocated_storage = 100
  
  db_subnet_group_name        = aws_db_subnet_group.subnet_group.name
  skip_final_snapshot         = true
  username                    = "catalogadmin"
  password                    = random_password.catalog_mysql.result
  vpc_security_group_ids = [aws_security_group.catalog_db_sg.id]
tags = {
   Project = "barakat-2025-capstone"
}

}



resource "aws_db_instance" "orders_service" {
  identifier                  = "project-bedrock-orders-service-db"
  db_name                     = "ordersServicedb"
  engine                      = "postgres"
  engine_version              = "16.4"
  instance_class              = "db.t3.micro"
   allocated_storage     = 20
  max_allocated_storage = 100
  
  db_subnet_group_name        = aws_db_subnet_group.subnet_group.name
  skip_final_snapshot         = true
  username                    = "orderadmin"
  password                    = random_password.orders_postgres.result
  vpc_security_group_ids = [aws_security_group.orders_db_sg.id]
tags = {
   Project = "barakat-2025-capstone"
}
}

resource "aws_secretsmanager_secret" "catalog_mysql_credentials" {
  name        = "bedrock/catalog/mysql-credentials"
  description = "Catalog MySQL RDS credentials"

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_secretsmanager_secret_version" "catalog_mysql_credentials" {
  secret_id = aws_secretsmanager_secret.catalog_mysql_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.catalog_service.username
    password = random_password.catalog_mysql.result
    endpoint = aws_db_instance.catalog_service.endpoint
    host     = split(":", aws_db_instance.catalog_service.endpoint)[0]
    port     = aws_db_instance.catalog_service.port
    database = aws_db_instance.catalog_service.db_name
  })

}

resource "aws_secretsmanager_secret" "orders_postgresql_credentials" {
  name        = "bedrock/orders/postgresql-credentials"
  description = "Orders PostgreSQL RDS credentials"

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_secretsmanager_secret_version" "orders_postgresql_credentials" {
  secret_id = aws_secretsmanager_secret.orders_postgresql_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.orders_service.username
    password = random_password.orders_postgres.result
    endpoint = aws_db_instance.orders_service.endpoint
    host     = split(":", aws_db_instance.orders_service.endpoint)[0]
    port     = aws_db_instance.orders_service.port
    database = aws_db_instance.orders_service.db_name
  })

}

resource "aws_iam_role" "app_sa_role" {
  name = "bedrock-app-sa-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:default:bedrock-app-sa"
          }
        }
      }
    ]
  })
  tags = {
     Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "bedrock-secrets-access"
  role = aws_iam_role.app_sa_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.catalog_mysql_credentials.arn,
          aws_secretsmanager_secret.orders_postgresql_credentials.arn
        ]
      }
    ]
  })

}

