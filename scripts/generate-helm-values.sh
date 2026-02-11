#!/bin/bash
set -e

echo "=== Generating Helm Values from Terraform Outputs ==="

TERRAFORM_OUTPUTS="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}/grading.json"

if [ -f "$TERRAFORM_OUTPUTS" ]; then
  echo "📦 Reading from grading.json artifact..."
  CATALOG_ENDPOINT=$(jq -r '.catalog_mysql_endpoint.value // empty' "$TERRAFORM_OUTPUTS")
  ORDERS_ENDPOINT=$(jq -r '.orders_postgresql_endpoint.value // empty' "$TERRAFORM_OUTPUTS")
else
  echo "🔧 Running terraform output locally..."
  REPO_ROOT=$(git rev-parse --show-toplevel)
  cd "$REPO_ROOT/terraform"
  CATALOG_ENDPOINT=$(terraform output -raw catalog_mysql_endpoint 2>/dev/null || echo "")
  ORDERS_ENDPOINT=$(terraform output -raw orders_postgresql_endpoint 2>/dev/null || echo "")
  cd "$REPO_ROOT"
fi
# Get secrets from AWS Secrets Manager
CATALOG_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id bedrock/catalog/mysql-credentials \
  --region us-east-1 \
  --query 'SecretString' \
  --output text 2>/dev/null || echo "")

ORDERS_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id bedrock/orders/postgresql-credentials \
  --region us-east-1 \
  --query 'SecretString' \
  --output text 2>/dev/null || echo "")

cd ..

# Check if RDS is provisioned
if [ -z "$CATALOG_ENDPOINT" ] || [ -z "$ORDERS_ENDPOINT" ]; then
  echo "⚠️  RDS instances not found. Using in-cluster databases."
  
  cat > ./project-bedrock-chart/values-generated.yaml << EOF
namespace: retail-app

rds:
  enabled: false

EOF
else
  echo "✅ RDS instances found. Generating values..."
  
  # Parse secrets
  CATALOG_USER=$(echo $CATALOG_SECRET | jq -r '.username')
  CATALOG_PASS=$(echo $CATALOG_SECRET | jq -r '.password')
  CATALOG_DB=$(echo $CATALOG_SECRET | jq -r '.database')
  
  ORDERS_USER=$(echo $ORDERS_SECRET | jq -r '.username')
  ORDERS_PASS=$(echo $ORDERS_SECRET | jq -r '.password')
  ORDERS_DB=$(echo $ORDERS_SECRET | jq -r '.database')
  
  # Generate values file
  cat > ./project-bedrock-chart/values-generated.yaml << EOF
namespace: retail-app

rds:
  enabled: true
  
  catalog:
    endpoint: "${CATALOG_ENDPOINT}"
    username: "${CATALOG_USER}"
    password: "${CATALOG_PASS}"
    database: "${CATALOG_DB}"
  
  orders:
    endpoint: "${ORDERS_ENDPOINT}"
    username: "${ORDERS_USER}"
    password: "${ORDERS_PASS}"
    database: "${ORDERS_DB}"


EOF

  echo "✅ Helm values generated at project-bedrock-chart/values-generated.yaml"
fi