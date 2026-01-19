# ============================================
# Terraform Configuration
# ============================================
# This file defines the required providers and versions
# Best Practice: Pin versions to avoid breaking changes

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # ============================================
  # Remote Backend Configuration (S3)
  # ============================================
  # WHY S3 Backend?
  # 1. Team collaboration - shared state
  # 2. State locking (with DynamoDB) - prevents concurrent modifications
  # 3. Encryption at rest - security
  # 4. Versioning - rollback capability
  # 
  # INTERVIEW TIP: "We use remote state because local state 
  # doesn't scale for teams and can be lost if machine fails"
  
  backend "s3" {
    bucket         = "devops-terraform-state-CHANGE-ME"  # Change to your bucket name
    key            = "eks-cluster/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # For state locking
  }
}

# ============================================
# AWS Provider
# ============================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-eks-assignment"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ============================================
# Kubernetes Provider (configured after EKS)
# ============================================
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
  }
}

# ============================================
# Helm Provider
# ============================================
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    }
  }
}
