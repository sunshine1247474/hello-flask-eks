# ============================================
# S3 Bucket for Terraform State
# ============================================
# WHY S3 for State?
# - Centralized state storage for team collaboration
# - Encryption at rest for security
# - Versioning for rollback/recovery
# - Works with DynamoDB for state locking
#
# INTERVIEW TIP: "We use S3 for Terraform state because:
# 1. Team members share the same state
# 2. CI/CD pipelines can access it
# 3. It's durable (99.999999999% - 11 nines!)
# 4. Supports encryption and versioning"
#
# NOTE: This is a "chicken and egg" problem - you need to 
# create this bucket BEFORE running terraform init with backend.
# Usually done manually or with a separate bootstrap script.

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "${var.project_name}-terraform-state"
    Purpose = "Terraform remote state storage"
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (security best practice)
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
# WHY DynamoDB for Locking?
# - Prevents concurrent terraform operations
# - Avoids state corruption
# - Required for team environments
#
# INTERVIEW TIP: "DynamoDB locking ensures only one person 
# or pipeline can modify infrastructure at a time. Without 
# it, two people running terraform apply simultaneously 
# could corrupt the state."

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"  # No cost when not in use
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
