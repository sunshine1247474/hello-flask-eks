# ============================================
# Terraform Outputs
# ============================================
# WHY Outputs?
# - Share information with other tools/pipelines
# - Document what was created
# - Used by GitHub Actions for deployment
#
# INTERVIEW TIP: "Outputs are how Terraform exposes 
# information about created resources. CI/CD pipelines 
# read these to know where to push images and deploy."

# ============================================
# EKS Outputs
# ============================================
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_certificate" {
  description = "Base64 encoded certificate for EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true  # Don't show in logs
}

output "eks_cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

# ============================================
# ECR Outputs
# ============================================
output "ecr_repository_url" {
  description = "URL of the ECR repository for pushing images"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

# ============================================
# IAM Outputs
# ============================================
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role (for CI/CD)"
  value       = aws_iam_role.github_actions.arn
}

# ============================================
# VPC Outputs
# ============================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# ============================================
# S3 Outputs
# ============================================
output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

# ============================================
# Useful Commands
# ============================================
output "configure_kubectl_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}
