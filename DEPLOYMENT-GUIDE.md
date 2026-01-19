# 🚀 מדריך פריסה ומחיקה מלא

## ⚠️ אזהרת עלויות

```
💰 עלות משוערת:
- EKS Control Plane: ~$0.10/שעה (~$72/חודש)
- NAT Gateway: ~$0.045/שעה (~$32/חודש)
- EC2 Node Groups (2x t3.medium): ~$0.05/שעה (~$36/חודש)
- Load Balancer: ~$0.025/שעה (~$18/חודש)
- סה"כ: ~$150-200/חודש אם משאירים פועל!

🎯 טיפ: הרץ את התרגיל, בדוק שעובד, ואז מחק הכל!
```

---

## 📋 דרישות מקדימות

```bash
# 1. AWS CLI מותקן ומוגדר
aws --version
aws configure  # הזן Access Key, Secret Key, Region

# 2. Terraform מותקן
terraform --version  # >= 1.5.0

# 3. kubectl מותקן
kubectl version --client

# 4. Helm מותקן
helm version

# 5. Docker מותקן
docker --version
```

---

## 🔧 שלב 1: Bootstrap - יצירת S3 Bucket ל-State

```bash
cd hello-flask-eks/infra/bootstrap

# Initialize and apply
terraform init
terraform plan
terraform apply -auto-approve

# שמור את ה-outputs!
# state_bucket_name = "hello-flask-tfstate-XXXXXXXXXXXX"
# dynamodb_table_name = "hello-flask-terraform-locks"
```

**📝 עדכן את `infra/versions.tf`:**
```hcl
backend "s3" {
  bucket         = "hello-flask-tfstate-YOUR_ACCOUNT_ID"  # <- שנה כאן
  key            = "eks-cluster/terraform.tfstate"
  region         = "eu-west-1"
  encrypt        = true
  dynamodb_table = "hello-flask-terraform-locks"
}
```

---

## 🏗️ שלב 2: פריסת Infrastructure עם Terraform

```bash
cd hello-flask-eks/infra

# Initialize with S3 backend
terraform init

# Preview changes
terraform plan

# Apply (זה לוקח 15-20 דקות!)
terraform apply -auto-approve

# שמור את ה-outputs:
# eks_cluster_name = "hello-flask-cluster"
# ecr_repository_url = "XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com/hello-flask-app"
```

---

## 🐳 שלב 3: Build & Push Docker Image

```bash
cd hello-flask-eks/app

# Login to ECR (החלף עם ה-URL שלך)
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com

# Build image
docker build -t hello-flask-app .

# Tag for ECR
docker tag hello-flask-app:latest XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com/hello-flask-app:latest

# Push to ECR
docker push XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com/hello-flask-app:latest
```

---

## ⎈ שלב 4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name hello-flask-cluster --region eu-west-1

# Verify connection
kubectl get nodes
# Expected: 2+ nodes (public + private)

kubectl get pods -A
# Expected: system pods running
```

---

## 📦 שלב 5: Deploy עם Helm

```bash
cd hello-flask-eks/helm/hello-flask

# Update values.yaml with your ECR URL
# image:
#   repository: "XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com/hello-flask-app"

# Install/Upgrade
helm upgrade --install hello-flask . \
  --set image.repository=XXXXXXXXXXXX.dkr.ecr.eu-west-1.amazonaws.com/hello-flask-app \
  --set image.tag=latest

# Check deployment
kubectl get pods
kubectl get svc

# Get LoadBalancer URL (wait 2-3 minutes)
kubectl get svc hello-flask -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## ✅ שלב 6: בדיקה שהכל עובד

```bash
# 1. Get the LoadBalancer URL
export LB_URL=$(kubectl get svc hello-flask -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "App URL: http://$LB_URL"

# 2. Test the app
curl http://$LB_URL
# Expected: {"message": "Hello from Flask on EKS!"}

curl http://$LB_URL/health
# Expected: {"status": "healthy"}

curl http://$LB_URL/ready
# Expected: {"status": "ready"}

# 3. Check logs
kubectl logs -l app=hello-flask --tail=50

# 4. Check HPA (auto-scaling)
kubectl get hpa
```

---

## 🔥 שלב 7: מחיקה מלאה (IMPORTANT!)

### שלב 7.1: מחק את ה-Helm Release
```bash
helm uninstall hello-flask

# Wait for LoadBalancer to be deleted
kubectl get svc
# (wait until no external LoadBalancer)
```

### שלב 7.2: מחק את ה-Infrastructure
```bash
cd hello-flask-eks/infra

# Destroy all resources (10-15 minutes)
terraform destroy -auto-approve
```

### שלב 7.3: מחק את ה-Bootstrap
```bash
cd hello-flask-eks/infra/bootstrap

# Empty the S3 bucket first (required before deletion)
aws s3 rm s3://hello-flask-tfstate-XXXXXXXXXXXX --recursive

# Destroy bootstrap
terraform destroy -auto-approve
```

### שלב 7.4: אמת שהכל נמחק
```bash
# Check EKS
aws eks list-clusters --region eu-west-1
# Expected: empty or no hello-flask-cluster

# Check ECR
aws ecr describe-repositories --region eu-west-1
# Expected: no hello-flask-app

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*hello-flask*" --region eu-west-1
# Expected: empty

# Check S3
aws s3 ls | grep hello-flask
# Expected: nothing
```

---

## 🧪 Quick Test Script

שמור כ-`test.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Testing Flask EKS Deployment..."

# Get LB URL
LB_URL=$(kubectl get svc hello-flask -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LB_URL" ]; then
    echo "❌ LoadBalancer not ready yet. Wait a few minutes."
    exit 1
fi

echo "📍 Testing: http://$LB_URL"

# Test endpoints
echo -n "/ endpoint: "
curl -s http://$LB_URL | jq .

echo -n "/health endpoint: "
curl -s http://$LB_URL/health | jq .

echo -n "/ready endpoint: "
curl -s http://$LB_URL/ready | jq .

echo ""
echo "✅ All tests passed!"
echo "🌐 App is accessible at: http://$LB_URL"
```

---

## 📊 Checklist מלא

- [ ] Bootstrap S3 + DynamoDB created
- [ ] versions.tf updated with bucket name
- [ ] Infrastructure deployed (VPC, EKS, ECR, IAM)
- [ ] Docker image built and pushed to ECR
- [ ] kubectl configured for EKS
- [ ] Helm chart deployed
- [ ] LoadBalancer URL accessible
- [ ] /health endpoint returns 200
- [ ] /ready endpoint returns 200
- [ ] HPA configured

### לאחר סיום:
- [ ] Helm release deleted
- [ ] Infrastructure destroyed
- [ ] S3 bucket emptied and destroyed
- [ ] All AWS resources verified deleted

---

## 🆘 Troubleshooting

### Pods stuck in Pending
```bash
kubectl describe pod <pod-name>
# Check for node selector/resource issues
```

### LoadBalancer stuck in Pending
```bash
kubectl describe svc hello-flask
# Check for subnet tags (kubernetes.io/role/elb = 1)
```

### Cannot pull image from ECR
```bash
# Verify ECR policy allows EKS nodes
# Check node IAM role has ecr:GetAuthorizationToken
```

### Terraform destroy stuck
```bash
# Try destroying specific resources first
terraform destroy -target=aws_eks_node_group.public
terraform destroy -target=aws_eks_node_group.private
terraform destroy -target=aws_eks_cluster.main
terraform destroy  # Then try full destroy
```
