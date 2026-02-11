# Project Bedrock - InnovateMart EKS Deployment

## Quick Start

### Prerequisites
- AWS CLI configured
- Terraform ≥ 1.0
- kubectl
- Helm ≥ 3.0
- Git

### Deploy in 3 Steps
```bash
# 1. Clone repository
git clone https://github.com/Ngorhzee/project-bedrock-capstone
cd project-bedrock-capstone

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 3. Deploy application
cd ..
bash scripts/deploy-app.sh
```

### Get Application URL
```bash
kubectl get svc ui -n retail-app
```

## Architecture
```
Internet → Load Balancer → EKS Cluster → Microservices
                              ├── UI Service
                              ├── Catalog Service (MySQL)
                              ├── Orders Service (PostgreSQL)
                              ├── Cart Service (DynamoDB)
                              └── Checkout Service (Redis)
```

## Project Structure
```
innovateMart/
├── terraform/          # Infrastructure as Code
├── project-bedrock-chart/  # Helm chart
├── scripts/           # Deployment scripts
└── lambda/            # Lambda function
```

## Essential Commands
```bash
# Check deployment
kubectl get pods -n retail-app
kubectl get svc -n retail-app

# View logs
kubectl logs -f deployment/ui -n retail-app

# Test developer access
aws configure --profile bedrock-dev
kubectl get pods -n retail-app

# Test Lambda
aws s3 cp test.jpg s3://bedrock-assets-${STUDENT_ID}/
aws logs tail /aws/lambda/bedrock-asset-processor --follow
```

## Verification

- [ ] All pods running
- [ ] LoadBalancer has external IP
- [ ] Application accessible in browser
- [ ] Lambda triggers on S3 upload
- [ ] Developer can view but not delete pods

## Troubleshooting

### LoadBalancer not accessible
```bash
# Add HTTP security group rule
LB_DNS=$(kubectl get svc ui -n retail-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
LB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='$LB_DNS'].LoadBalancerArn" --output text)
LB_SG=$(aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN --query 'LoadBalancers[0].SecurityGroups[0]' --output text)
aws ec2 authorize-security-group-ingress --group-id $LB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
```

### Pods not running
```bash
kubectl get events -n retail-app --sort-by='.lastTimestamp'
kubectl describe pod <pod-name> -n retail-app
```

### Helm conflicts
```bash
kubectl delete namespace retail-app
sleep 10
bash scripts/deploy-app.sh
```

## Cleanup
```bash
# Delete application
helm uninstall retail-store -n retail-app

# Delete infrastructure
cd terraform
terraform destroy -auto-approve
```

## Grading Deliverables

1. GitHub repository link
2. `grading.json` in repo root
3. Application URL
4. Developer credentials from: `terraform output`
5. All resources tagged: `Project: barakat-2025-capstone`



- Documentation: This README
- Issues: GitHub Issues
- Email: ngoziamolo02@gmail.com

---

**Author:** Ngozi Amolo  
**Course:** Cloud Engineering  
**Date:** February 2026
