# 1. Deploy infrastructure with Terraform
# cd terraform
# terraform init
# terraform plan
# terraform apply

# 2. Wait for EKS cluster to be ready (5-15 minutes)
aws eks describe-cluster \
  --name project-bedrock-cluster \
  --region us-east-1 \
  --query 'cluster.status'

# 3. Configure kubectl
aws eks update-kubeconfig \
  --region us-east-1 \
  --name project-bedrock-cluster

# 4. Verify connection
kubectl get nodes

# 5. Now create namespace
kubectl create namespace retail-app
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml -n retail-app

# # 6. Deploy application
pushd ../project-bedrock-chart
helm install retail-store .\
 --namespace retail-app
 --set serviceType=LoadBalancer
popd

echo "Checking Helm release..."
helm list -n retail-app

echo "Checking pods (this may take 2-3 minutes)..."
kubectl get pods -n retail-app

echo "Checking services..."
kubectl get svc -n retail-app

aws eks create-addon \
  --cluster-name project-bedrock-cluster \
  --addon-name amazon-cloudwatch-observability \
  --region us-east-1

