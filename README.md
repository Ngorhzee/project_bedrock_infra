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
# Project Bedrock - Architecture Diagrams


## Main Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS CLOUD (us-east-1)                               │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │              VPC: project-bedrock-vpc (10.0.0.0/16)                   │ │
│  │                                                                       │ │
│  │  ┌─────────────────────┐         ┌─────────────────────┐            │ │
│  │  │  PUBLIC SUBNET 1    │         │  PUBLIC SUBNET 2    │            │ │
│  │  │  us-east-1a         │         │  us-east-1b         │            │ │
│  │  │  10.0.1.0/24        │         │  10.0.2.0/24        │            │ │
│  │  │                     │         │                     │            │ │
│  │  │  ┌───────────────┐  │         │                     │            │ │
│  │  │  │ Internet      │  │         │                     │            │ │
│  │  │  │ Gateway       │◄─┼─────────┼─── Internet         │            │ │
│  │  │  └───────────────┘  │         │                     │            │ │
│  │  │                     │         │                     │            │ │
│  │  │  ┌───────────────┐  │         │                     │            │ │
│  │  │  │ NAT Gateway   │  │         │                     │            │ │
│  │  │  └───────────────┘  │         │                     │            │ │
│  │  │                     │         │                     │            │ │
│  │  │  ┌─────────────────────────────────────────────┐   │            │ │
│  │  │  │   Application Load Balancer                 │   │            │ │
│  │  │  │   Type: internet-facing                     │   │            │ │
│  │  │  │   Scheme: HTTP/HTTPS (Port 80/443)          │   │            │ │
│  │  │  └─────────────────────────────────────────────┘   │            │ │
│  │  └──────────────┬──────┘         └─────────────────────┘            │ │
│  │                 │                                                   │ │
│  │  ┌──────────────▼──────┐         ┌─────────────────────┐            │ │
│  │  │  PRIVATE SUBNET 1   │         │  PRIVATE SUBNET 2   │            │ │
│  │  │  us-east-1a         │         │  us-east-1b         │            │ │
│  │  │  10.0.3.0/24        │         │  10.0.4.0/24        │            │ │
│  │  │                     │         │                     │            │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │
│  │  │  │       EKS CLUSTER: project-bedrock-cluster             │     │ │
│  │  │  │       Kubernetes Version: 1.34                         │     │ │
│  │  │  │                                                         │     │ │
│  │  │  │  ┌──────────────────────────────────────────────────┐ │     │ │
│  │  │  │  │    NAMESPACE: retail-app                         │ │     │ │
│  │  │  │  │                                                  │ │     │ │
│  │  │  │  │    ┌─────────────┐         ┌─────────────┐     │ │     │ │
│  │  │  │  │    │ UI Service  │────────▶│  Catalog    │     │ │     │ │
│  │  │  │  │    │ (Frontend)  │         │  Service    │     │ │     │ │
│  │  │  │  │    │ Port: 8080  │         │  Port: 8080 │     │ │     │ │
│  │  │  │  │    └─────────────┘         └──────┬──────┘     │ │     │ │
│  │  │  │  │            │                       │            │ │     │ │
│  │  │  │  │            ▼                       ▼            │ │     │ │
│  │  │  │  │    ┌─────────────┐         ┌─────────────┐     │ │     │ │
│  │  │  │  │    │    Cart     │         │    MySQL    │     │ │     │ │
│  │  │  │  │    │  Service    │         │  (Catalog)  │     │ │     │ │
│  │  │  │  │    │ Port: 8080  │         │  Port: 3306 │     │ │     │ │
│  │  │  │  │    └─────────────┘         └─────────────┘     │ │     │ │
│  │  │  │  │            │                                    │ │     │ │
│  │  │  │  │            ▼                                    │ │     │ │
│  │  │  │  │    ┌─────────────┐         ┌─────────────┐     │ │     │ │
│  │  │  │  │    │   Orders    │────────▶│ PostgreSQL  │     │ │     │ │
│  │  │  │  │    │  Service    │         │  (Orders)   │     │ │     │ │
│  │  │  │  │    │ Port: 8080  │         │ Port: 5432  │     │ │     │ │
│  │  │  │  │    └─────────────┘         └─────────────┘     │ │     │ │
│  │  │  │  │                                                 │ │     │ │
│  │  │  │  │    ┌─────────────┐         ┌─────────────┐     │ │     │ │
│  │  │  │  │    │  Checkout   │────────▶│    Redis    │     │ │     │ │
│  │  │  │  │    │  Service    │         │   (Cache)   │     │ │     │ │
│  │  │  │  │    │ Port: 8080  │         │ Port: 6379  │     │ │     │ │
│  │  │  │  │    └─────────────┘         └─────────────┘     │ │     │ │
│  │  │  │  │                                                 │ │     │ │
│  │  │  │  │    ┌─────────────┐         ┌─────────────┐     │ │     │ │
│  │  │  │  │    │   Assets    │         │  RabbitMQ   │     │ │     │ │
│  │  │  │  │    │  Service    │         │   (Queue)   │     │ │     │ │
│  │  │  │  │    │ Port: 8080  │         │ Port: 5672  │     │ │     │ │
│  │  │  │  │    └─────────────┘         └─────────────┘     │ │     │ │
│  │  │  │  └──────────────────────────────────────────────────┘ │     │ │
│  │  │  │                                                         │     │ │
│  │  │  │  Worker Nodes:                                          │     │ │
│  │  │  │  • ip-10-0-1-x (t3.medium) ──────────────────────────┐ │     │ │
│  │  │  │  • ip-10-0-2-y (t3.medium)                           │ │     │ │
│  │  │  └──────────────────────────────────────────────────────┼─┘     │ │
│  │  │                     │         │                         │       │ │
│  │  │  ┌──────────────────▼─────────▼─────────────────┐      │       │ │
│  │  │  │      RDS INSTANCES (BONUS FEATURE)           │      │       │ │
│  │  │  │                                               │      │       │ │
│  │  │  │  ┌─────────────────────────────────────┐     │      │       │ │
│  │  │  │  │  catalog-mysql                      │◄────┘      │       │ │
│  │  │  │  │  Engine: MySQL 8.0                  │            │       │ │
│  │  │  │  │  Instance: db.t3.micro              │            │       │ │
│  │  │  │  │  Storage: 20GB                      │            │       │ │
│  │  │  │  └─────────────────────────────────────┘            │       │ │
│  │  │  │                                                      │       │ │
│  │  │  │  ┌─────────────────────────────────────┐            │       │ │
│  │  │  │  │  orders-postgresql                  │◄───────────┘       │ │
│  │  │  │  │  Engine: PostgreSQL 16              │                    │ │
│  │  │  │  │  Instance: db.t3.micro              │                    │ │
│  │  │  │  │  Storage: 20GB (Encrypted)          │                    │ │
│  │  │  │  └─────────────────────────────────────┘                    │ │
│  │  │  └──────────────────────────────────────────────────────────┘  │ │
│  │  └─────────────────────┘         └─────────────────────┘            │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                    SERVERLESS COMPONENTS                              │ │
│  │                                                                       │ │
│  │  ┌─────────────────────┐         ┌─────────────────────┐            │ │
│  │  │   S3 Bucket         │ Event   │   Lambda Function   │            │ │
│  │  │   bedrock-assets-*  │────────▶│   bedrock-asset-    │            │ │
│  │  │   (Private)         │         │   processor         │            │ │
│  │                                  │   Runtime: Python   │            │ │
│  │  └─────────────────────┘         └──────────┬──────────┘            │ │
│  │                                              │                       │ │
│  └──────────────────────────────────────────────┼───────────────────────┘ │
│                                                  │                         │
│  ┌───────────────────────────────────────────────▼─────────────────────┐ │
│  │                    MONITORING & LOGGING                              │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────┐    │ │
│  │  │               CloudWatch Logs                               │    │ │
│  │  │   • /aws/eks/project-bedrock-cluster/cluster (Control Plane)│    │ │
│  │  │   • /aws/containerinsights/* (Application Logs)             │    │ │
│  │  │   • /aws/lambda/bedrock-asset-processor (Lambda Logs)       │    │ │
│  │  └─────────────────────────────────────────────────────────────┘    │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────┐    │ │
│  │  │               AWS Secrets Manager                           │    │ │
│  │  │   • bedrock/catalog/mysql-credentials                       │    │ │
│  │  │   • bedrock/orders/postgresql-credentials                   │    │ │
│  │  └─────────────────────────────────────────────────────────────┘    │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────┐    │ │
│  │  │               IAM                                           │    │ │
│  │  │   • bedrock-dev-view (ReadOnly + S3 Put + K8s View)        │    │ │
│  │  │   • EKS Cluster Role                                        │    │ │
│  │  │   • EKS Node Role                                           │    │ │
│  │  │   • Lambda Execution Role                                   │    │ │
│  │  └─────────────────────────────────────────────────────────────┘    │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

                               INTERNET
                                  │
                                  ▼
                        ┌───────────────────┐
                        │   End Users       │
                        └───────────────────┘
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          REQUEST FLOW                                │
└──────────────────────────────────────────────────────────────────────┘

  User Browser
      │
      │ 1. HTTP Request
      ▼
  ┌────────────────────┐
  │ Application Load   │
  │ Balancer (ALB)     │
  │ Port: 80/443       │
  └─────────┬──────────┘
            │
            │ 2. Route to NodePort (32720)
            ▼
  ┌────────────────────┐
  │ EKS Worker Node    │
  │ Security Group:    │
  │ Allow 30000-32767  │
  └─────────┬──────────┘
            │
            │ 3. Forward to Pod
            ▼
  ┌────────────────────┐
  │ UI Service Pod     │
  │ IP: 10.0.x.x       │
  │ Port: 8080         │
  └─────────┬──────────┘
            │
            │ 4. API Calls (Internal ClusterIP)
            ├──────────┬──────────┬──────────┐
            ▼          ▼          ▼          ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ Catalog  │ │   Cart   │ │  Orders  │ │ Checkout │
    │ Service  │ │ Service  │ │ Service  │ │ Service  │
    └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
         │            │            │            │
         │ 5. DB     │ 5. DB     │ 5. DB     │ 5. Cache
         │ Query     │ Query     │ Query     │ Read/Write
         ▼            ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  MySQL   │ │ DynamoDB │ │PostgreSQL│ │  Redis   │
    │  3306    │ │   8000   │ │   5432   │ │  6379    │
    └──────────┘ └──────────┘ └──────────┘ └──────────┘
         │                         │
         │ BONUS: External DB      │
         ▼                         ▼
    ┌──────────┐            ┌──────────┐
    │RDS MySQL │            │RDS       │
    │ (Managed)│            │PostgreSQL│
    └──────────┘            └──────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                       IMAGE UPLOAD FLOW                              │
└──────────────────────────────────────────────────────────────────────┘

  User Browser
      │
      │ 1. Upload Image
      ▼
  ┌────────────────────┐
  │ S3 Bucket          │
  │ bedrock-assets-*   │
  │ Private, Encrypted │
  └─────────┬──────────┘
            │
            │ 2. S3 Event Notification
            │    (ObjectCreated:*)
            ▼
  ┌────────────────────┐
  │ Lambda Function    │
  │ bedrock-asset-     │
  │ processor          │
  └─────────┬──────────┘
            │
            │ 3. Process & Log
            │    "Image received: filename.jpg"
            ▼
  ┌────────────────────┐
  │ CloudWatch Logs    │
  │ /aws/lambda/...    │
  └────────────────────┘
```

---

## Security & Access Control

```
┌──────────────────────────────────────────────────────────────────────┐
│                    SECURITY ARCHITECTURE                             │
└──────────────────────────────────────────────────────────────────────┘

  ┌────────────────────┐
  │  IAM User:         │
  │  bedrock-dev-view  │
  │                    │
  │  Permissions:      │
  │  ✅ ReadOnlyAccess │
  │  ✅ S3:PutObject   │
  │  ❌ EC2:Terminate  │
  └─────────┬──────────┘
            │
            │ Mapped to Kubernetes RBAC
            ▼
  ┌────────────────────┐
  │  Kubernetes RBAC   │
  │                    │
  │  ClusterRole: view │
  │  ✅ get pods       │
  │  ✅ list pods      │
  │  ✅ watch pods     │
  │  ❌ delete pods    │
  └────────────────────┘

  ┌────────────────────────────────────────┐
  │       Security Group Rules             │
  ├────────────────────────────────────────┤
  │                                        │
  │  ALB Security Group:                   │
  │  ┌──────────────────────────────────┐  │
  │  │ Inbound:                         │  │
  │  │ • Port 80 from 0.0.0.0/0        │  │
  │  │ • Port 443 from 0.0.0.0/0       │  │
  │  └──────────────────────────────────┘  │
  │              │                         │
  │              ▼                         │
  │  Node Security Group:                  │
  │  ┌──────────────────────────────────┐  │
  │  │ Inbound:                         │  │
  │  │ • Port 30000-32767 from ALB SG  │  │
  │  │ • All traffic from Node SG      │  │
  │  └──────────────────────────────────┘  │
  │              │                         │
  │              ▼                         │
  │  RDS Security Group:                   │
  │  ┌──────────────────────────────────┐  │
  │  │ Inbound:                         │  │
  │  │ • Port 3306 from Node SG        │  │
  │  │ • Port 5432 from Node SG        │  │
  │  └──────────────────────────────────┘  │
  └────────────────────────────────────────┘
```

---

## CI/CD Pipeline Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS WORKFLOW                           │
└──────────────────────────────────────────────────────────────────────┘

  Developer
      │
      │ git push
      ▼
  ┌─────────────┐
  │   GitHub    │
  │ Repository  │
  └──────┬──────┘
         │
         │ Trigger on: Pull Request
         ▼
  ┌────────────────────┐
  │ terraform plan     │
  │ (Preview Changes)  │
  └────────────────────┘

         │ Trigger on: Merge to main
         ▼
  ┌────────────────────┐
  │ 1. terraform init  │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 2. terraform apply │
  │    (Auto-approve)  │
  └─────────┬──────────┘
            │
            │ Creates:
            ├─── VPC
            ├─── EKS Cluster
            ├─── Node Groups
            ├─── IAM Resources
            ├─── S3 Bucket
            ├─── Lambda Function
            └─── RDS (if enabled)
            │
            ▼
  ┌────────────────────┐
  │ 3. Wait for EKS    │
  │    Status: ACTIVE  │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 4. Configure       │
  │    kubectl         │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 5. Generate Helm   │
  │    Values from     │
  │    Terraform       │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 6. Deploy App      │
  │    with Helm       │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 7. Wait for Pods   │
  │    Status: Running │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 8. Generate        │
  │    grading.json    │
  └─────────┬──────────┘
            ▼
  ┌────────────────────┐
  │ 9. Upload Artifact │
  └────────────────────┘

         ✅ DEPLOYMENT COMPLETE
```

---

## Resource Tagging

```
All AWS Resources Tagged With:
┌────────────────────────────────┐
│  Project: barakat-2025-capstone│
└────────────────────────────────┘

Applied to:
• VPC and Subnets
• EKS Cluster
• EC2 Instances (Nodes)
• S3 Bucket
• Lambda Function
• RDS Instances
• IAM Roles and Users
• Security Groups
• CloudWatch Log Groups
```
## Grading Deliverables

1. GitHub repository link : https://github.com/Ngorhzee/project-bedrock-capstone
2. `grading.json` in repo root
3. Application URL

4. All resources tagged: `Project: barakat-2025-capstone`



- Documentation: This README
- Issues: GitHub Issues
- Email: ngoziamolo02@gmail.com

---

**Author:** Ngozi Amolo  
**Course:** Cloud Engineering  
**Date:** February 2026
