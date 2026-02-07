
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file  = "../lambda/lambda_function.py"
  output_path = "${path.module}/../lambda/lambda.zip"
  
}
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/lambda_log_group"
  retention_in_days = 14

  tags = {
    Project = "Bedrock"
  
  }
}
resource "aws_s3_bucket" "s3_asset_bucket" {
    bucket = "bedrock-assets-alt-soe-025-1528"
    tags = {
    Project = "Bedrock"
    Terraform   = "true"
  }

    
  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.s3_asset_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.s3_asset_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "assets_lambda" {
  filename = data.archive_file.lambda_zip.output_path
  role = aws_iam_role.lambda_execution_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name = "bedrock-asset-processor"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  logging_config {
    log_format = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
  depends_on = [ aws_cloudwatch_log_group.lambda_log_group ]
  
}

resource "aws_lambda_permission" "lambda_s3_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.assets_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_asset_bucket.arn
  
}
resource "aws_s3_bucket_notification" "event_notification" {
  bucket = aws_s3_bucket.s3_asset_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.assets_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.lambda_s3_permission]
  
}
resource "aws_iam_role_policy" "lambda_role_policy" {
    role = aws_iam_role.lambda_execution_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:logs:*:*:*"
        },
        {
            Action = [
            
            "s3:GetObject",
            "s3:GetObjectVersion"
            ]
            Effect   = "Allow"
            Resource = [
            aws_s3_bucket.s3_asset_bucket.arn,
            "${aws_s3_bucket.s3_asset_bucket.arn}/*"
            ]
        }
        ]
    })
  
}


