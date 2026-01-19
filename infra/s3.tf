# ============================================
# S3 & DynamoDB Resources Moved to Bootstrap
# ============================================
# 
# The S3 bucket and DynamoDB table for Terraform state
# are now created in the bootstrap/ directory.
#
# Why? "Chicken and egg" problem - the bucket must exist
# BEFORE terraform init can run with the S3 backend.
#
# See: infra/bootstrap/main.tf
#
# INTERVIEW TIP: "We separate state backend creation into
# a bootstrap phase because the backend must exist before
# we can initialize Terraform with remote state."
