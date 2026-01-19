# ============================================
# Bootstrap - Create S3 Bucket for Terraform State
# ============================================
# RUN THIS FIRST! Before main infrastructure.
#
# Why separate?
# - S3 bucket must exist before terraform init
# - This is the "chicken and egg" solution
# - Run once, then run main infrastructure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "project_name" {
  default = "hello-flask"
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}

# ============================================
# S3 Bucket for Terraform State
# ============================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"

  # ALLOW destroy for this exercise!
  # In production, set this to true
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name    = "${var.project_name}-terraform-state"
    Purpose = "Terraform remote state storage"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================
# DynamoDB Table for State Locking
# ============================================
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-terraform-locks"
    Purpose = "Terraform state locking"
  }
}

# ============================================
# Outputs - Use these for main infrastructure
# ============================================
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "next_steps" {
  value = <<-EOT
    
    ✅ Bootstrap complete! Now update your main infrastructure:
    
    1. Edit infra/versions.tf:
       bucket         = "${aws_s3_bucket.terraform_state.bucket}"
       dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    
    2. Run main infrastructure:
       cd ../
       terraform init
       terraform plan
       terraform apply
    
  EOT
}
