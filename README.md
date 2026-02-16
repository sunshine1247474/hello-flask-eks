# 🚀 DevOps EKS Assignment - Complete Solution

![AWS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)
![Docker](https://img.shields.io/badge/Container-Docker-blue?logo=docker)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Package-Helm-0F1689?logo=helm)

A complete DevOps pipeline: **Terraform → Docker → EKS → Helm → GitHub Actions**

> 📖 **[קרא את מדריך הפריסה המלא (DEPLOYMENT-GUIDE.md)](./DEPLOYMENT-GUIDE.md)** - Step-by-step instructions for deploying and destroying!

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    GitHub Actions CI/CD                              │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │    │
│  │  │ 1. Build    │──│ 2. Push     │──│ 3. Deploy   │──│ 4. Verify  │  │    │
│  │  │    Docker   │  │    to ECR   │  │    to EKS   │  │    Health  │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘  │    │
│  └───────────────────────────┬─────────────────────────────────────────┘    │
│                              │                                               │
└──────────────────────────────┼───────────────────────────────────────────────┘
                               │ OIDC Auth
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD                                       │
│                                                                              │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐   │
│   │     ECR      │     │   S3 Bucket  │     │         VPC              │   │
│   │  (Images)    │     │  (TF State)  │     │  ┌─────────┐ ┌─────────┐ │   │
│   └──────────────┘     └──────────────┘     │  │ Public  │ │ Private │ │   │
│          │                                   │  │ Subnet  │ │ Subnet  │ │   │
│          │                                   │  │         │ │         │ │   │
│          │                                   │  │ ┌─────┐ │ │ ┌─────┐ │ │   │
│          └──────────────────────────────────►│  │ │Node │ │ │ │Node │ │ │   │
│                                              │  │ │Group│ │ │ │Group│ │ │   │
│                                              │  │ └─────┘ │ │ └─────┘ │ │   │
│                                              │  └────┬────┘ └────┬────┘ │   │
│                                              │       │           │      │   │
│                                              │       └─────┬─────┘      │   │
│                                              │             │            │   │
│                                              │      ┌──────┴──────┐     │   │
│                                              │      │ EKS Cluster │     │   │
│                                              │      │  (Control)  │     │   │
│                                              │      └──────┬──────┘     │   │
│                                              └─────────────┼────────────┘   │
│                                                            │                │
│                                              ┌─────────────┴──────────────┐ │
│                                              │    Network Load Balancer   │ │
│                                              └─────────────┬──────────────┘ │
│                                                            │                │
└────────────────────────────────────────────────────────────┼────────────────┘
                                                             │
                                                             ▼
                                                        🌐 Internet
                                                        (Users Access)
```

---

## 📋 What This Project Covers

| Component | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Terraform** | Infrastructure as Code | Reproducible, version-controlled infrastructure |
| **VPC** | Network Isolation | Security boundary for our resources |
| **EKS** | Managed Kubernetes | Production-grade container orchestration |
| **ECR** | Private Container Registry | Secure image storage with IAM integration |
| **Docker** | Containerization | Consistent runtime environment |
| **Helm** | K8s Package Manager | Templated, repeatable deployments |
| **GitHub Actions** | CI/CD Automation | Automated build and deploy pipeline |
| **OIDC** | Secure Auth | No stored credentials in CI/CD |

---

## 🏗️ Project Structure

```
devops-eks-project/
├── infra/                          # 🏗️ Terraform Infrastructure
│   ├── versions.tf                 # Provider versions & backend config
│   ├── variables.tf                # Input variables
│   ├── vpc.tf                      # VPC, subnets, NAT, IGW
│   ├── eks.tf                      # EKS cluster and node groups
│   ├── ecr.tf                      # Container registry
│   ├── iam.tf                      # IAM roles and policies
│   ├── s3.tf                       # State bucket and locks
│   └── outputs.tf                  # Output values
├── app/                            # 🐍 Flask Application
│   ├── app.py                      # Main application
│   ├── requirements.txt            # Python dependencies
│   └── Dockerfile                  # Container image definition
├── helm/                           # ⎈ Helm Chart
│   └── hello-flask/
│       ├── Chart.yaml              # Chart metadata
│       ├── values.yaml             # Default values
│       └── templates/
│           ├── deployment.yaml     # K8s Deployment
│           ├── service.yaml        # K8s Service
│           ├── serviceaccount.yaml # K8s ServiceAccount
│           └── hpa.yaml            # Horizontal Pod Autoscaler
├── .github/workflows/              # 🔄 CI/CD Pipelines
│   ├── ci-cd.yaml                  # Build & Deploy pipeline
│   └── terraform.yaml              # Infrastructure pipeline (BONUS)
└── README.md                       # 📖 This file
```

---

## 🚀 Quick Start Guide

### Prerequisites

Install these tools locally:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker
curl -fsSL https://get.docker.com | sh
```

### Step 1: Configure AWS

```bash
# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (eu-west-1), Output format (json)

# Verify
aws sts get-caller-identity
```

### Step 2: Deploy Infrastructure (Terraform)

```bash
cd infra

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the infrastructure (~15-20 minutes)
terraform apply

# Save the outputs
terraform output > ../terraform-outputs.txt
```

### Step 3: Configure kubectl

```bash
# Get the command from Terraform output
aws eks update-kubeconfig --name hello-flask-cluster --region eu-west-1

# Verify
kubectl get nodes
```

### Step 4: Build & Push Docker Image

```bash
cd ../app

# Login to ECR
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com

# Build
docker build -t hello-flask:1.0 .

# Tag
docker tag hello-flask:1.0 <ECR_URL>:1.0

# Push
docker push <ECR_URL>:1.0
```

### Step 5: Deploy with Helm

```bash
cd ../helm/hello-flask

# Update values.yaml with your ECR URL
# Then deploy:
helm upgrade --install hello-flask . \
  --set image.repository=<ECR_URL> \
  --set image.tag=1.0

# Get the public URL
kubectl get svc hello-flask -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 6: Test the Application

```bash
# Get the LoadBalancer URL
export APP_URL=$(kubectl get svc hello-flask -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$APP_URL/
curl http://$APP_URL/health
curl http://$APP_URL/ready
```

---

## 🔧 GitHub Actions Setup

### Required Secrets

Add these secrets to your GitHub repository:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `terraform output github_actions_role_arn` |
| `ECR_REGISTRY` | ECR registry URL | `terraform output ecr_repository_url` |

### Enable OIDC

1. In `infra/iam.tf`, update the GitHub repo in the OIDC trust policy
2. Apply Terraform changes
3. Push to main branch to trigger the pipeline

---

## 🧹 Cleanup (Remove Everything)

### Step 1: Remove Helm Release

```bash
helm uninstall hello-flask
```

### Step 2: Destroy Infrastructure

```bash
cd infra

# First, empty the ECR repository
aws ecr batch-delete-image \
  --repository-name hello-flask-app \
  --image-ids "$(aws ecr list-images --repository-name hello-flask-app --query 'imageIds[*]' --output json)"

# Destroy all resources
terraform destroy

# Manually delete S3 bucket (if it has versioning)
aws s3 rb s3://<bucket-name> --force
```

---

## 💡 Questions & Answers

### "Why Terraform instead of CloudFormation?"

> "Terraform is cloud-agnostic, has a larger ecosystem of providers, and HCL is more readable than JSON/YAML. The state management and plan/apply workflow makes changes predictable. However, CloudFormation has tighter AWS integration and doesn't require state management."

### "Why EKS instead of ECS?"

> "EKS gives us Kubernetes, which is the industry standard. It's portable - the same manifests work on any K8s cluster. ECS is simpler and cheaper for small workloads, but EKS is better for complex applications and team skill portability."

### "Why OIDC instead of Access Keys?"

> "OIDC is more secure because there are no long-lived credentials to manage, store, or rotate. GitHub exchanges its JWT for temporary AWS credentials that expire quickly. Access keys are static and could be compromised."

### "Why Service type LoadBalancer instead of Ingress?"

> "LoadBalancer is simpler for this assignment - one service, one endpoint. For multiple services, we'd use Ingress with AWS ALB Controller, which gives us path-based routing, SSL termination, and a single Load Balancer for cost savings."

### "Why nodes in both public and private subnets?"

> "The assignment requires it. In production, we'd typically put all nodes in private subnets and expose services only through a Load Balancer. Public nodes have more attack surface. But having nodes in both subnets demonstrates understanding of networking."

---

## 💰 Cost Estimate

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| EKS Control Plane | ~$72 |
| 4x t3.medium nodes | ~$120 |
| NAT Gateway | ~$32 + data |
| Load Balancer | ~$16 + data |
| ECR Storage | ~$1 |
| S3 State | ~$0.10 |
| **Total** | **~$250/month** |

> ⚠️ **Don't forget to destroy resources when done!**

---

## 📚 Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [GitHub Actions for AWS](https://github.com/aws-actions)

---

## 👤 Author

DevOps Assignment Solution - Complete CI/CD Pipeline with Monitoring

---

**Good luck with your interview!** 🎯
