#!/bin/bash
set -e  # Exit on error

echo "=== Deploying Retail Store Application ==="

CLUSTER_NAME="project-bedrock-cluster"
REGION="us-east-1"
NAMESPACE="retail-app"

# Wait for cluster to be active
echo "Waiting for EKS cluster..."
until [ "$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text)" == "ACTIVE" ]; do
    echo "Cluster not ready, waiting 30s..."
    sleep 30
done
echo "Cluster is active"

# Configure kubectl
echo "Configuring kubectl..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
kubectl get nodes

# Create namespace (idempotent)
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Clean up any existing deployments from previous runs
echo "Cleaning up any existing deployments..."
kubectl delete all --all -n $NAMESPACE 2>/dev/null || true

# Remove pre-existing ServiceAccounts that would conflict with Helm
# (Helm requires owner annotations; remove SAs that lack them)
echo "Checking for conflicting ServiceAccounts..."
CONFLICTING_SAS=("catalog" "orders" "ui")
for sa in "${CONFLICTING_SAS[@]}"; do
  if kubectl get sa "$sa" -n $NAMESPACE >/dev/null 2>&1; then
    ANNOTATION=$(kubectl get sa "$sa" -n $NAMESPACE -o jsonpath='{.metadata.annotations.meta.helm.sh/release-name}' 2>/dev/null || echo "")
    if [ -z "$ANNOTATION" ]; then
      echo "Deleting existing ServiceAccount '$sa' (no Helm annotations)"
      kubectl delete sa "$sa" -n $NAMESPACE --ignore-not-found || true
    else
      echo "ServiceAccount '$sa' is already managed by Helm (release=$ANNOTATION), leaving it."
    fi
  fi
done

echo "🔧 Generating Helm values..."
bash scripts/generate-helm-values.sh

# Check if using RDS
RDS_ENABLED=$(grep "enabled: true" project-bedrock-chart/values-generated.yaml 2>/dev/null || echo "")

if [ -n "$RDS_ENABLED" ]; then
  echo "🗄️  Deploying with RDS databases..."
  
  # Wait for RDS instances to be available
  echo "⏳ Waiting for RDS instances..."
  aws rds wait db-instance-available \
    --db-instance-identifier catalog-mysql \
    --region $REGION 2>/dev/null || echo "Catalog MySQL already available"
  
  aws rds wait db-instance-available \
    --db-instance-identifier orders-postgresql \
    --region $REGION 2>/dev/null || echo "Orders PostgreSQL already available"
  
  echo "✅ RDS instances ready"
else
  echo "🗄️  Deploying with in-cluster databases..."
fi
# Deploy Helm chart if exists
if [ -d "project-bedrock-chart" ]; then
    echo "📊 Deploying Helm chart..."
    helm upgrade --install retail-store ./project-bedrock-chart \
        --namespace $NAMESPACE \
        --values project-bedrock-chart/values-generated.yaml \
        --wait --timeout 10m
fi

# Wait for pods
echo "⏳ Waiting for pods (up to 10 minutes)..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=600s || true

# Show status
echo ""
echo "=== Deployment Complete! ==="
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
echo ""
echo "🌐 LoadBalancer URL:"
kubectl get svc ui -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""