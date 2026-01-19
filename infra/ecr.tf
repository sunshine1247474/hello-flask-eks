# ============================================
# ECR - Elastic Container Registry
# ============================================
# WHY ECR?
# - Private Docker registry in AWS
# - Native IAM integration (no separate credentials)
# - Integrated with EKS (nodes can pull automatically)
# - Vulnerability scanning built-in
#
# INTERVIEW TIP: "We use ECR instead of DockerHub because:
# 1. It's private by default
# 2. Uses IAM for auth (no extra credentials)
# 3. Faster pulls since it's in the same region
# 4. Native integration with EKS and GitHub Actions"
#
# COST: $0.10/GB/month for storage + data transfer

resource "aws_ecr_repository" "app" {
  name = "${var.project_name}-app"

  # Scan images for vulnerabilities on push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Use immutable tags in production
  # INTERVIEW TIP: "Immutable tags prevent overwriting images,
  # which helps with rollback and audit trails"
  image_tag_mutability = "MUTABLE"  # Using MUTABLE for development

  # Encryption at rest
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

# ============================================
# ECR Lifecycle Policy
# ============================================
# WHY Lifecycle Policy?
# - Automatically clean up old images
# - Reduce storage costs
# - Keep only recent images
#
# INTERVIEW TIP: "Without lifecycle policy, ECR would 
# accumulate thousands of images over time, increasing 
# storage costs. We keep only the last 30 images."

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================
# ECR Repository Policy (optional)
# ============================================
# Allows cross-account access if needed
# resource "aws_ecr_repository_policy" "app" {
#   repository = aws_ecr_repository.app.name
#   policy     = jsonencode({...})
# }
