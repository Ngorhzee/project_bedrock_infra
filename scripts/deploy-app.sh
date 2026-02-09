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

# Deploy application
echo "Deploying application..."
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml -n $NAMESPACE

# Deploy Helm chart if exists
if [ -d "project-bedrock-chart" ]; then
    echo "📊 Deploying Helm chart..."
    helm upgrade --install retail-store ./project-bedrock-chart \
        --namespace $NAMESPACE \
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