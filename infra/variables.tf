# ============================================
# Input Variables
# ============================================
# Variables allow customization without modifying code
# Best Practice: Use descriptive names and add validation

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "Must be a valid AWS region format (e.g., eu-west-1)"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hello-flask"
}

# ============================================
# VPC Variables
# ============================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "First availability zone"
  type        = string
  default     = "eu-west-1a"
}

variable "availability_zone_2" {
  description = "Second availability zone"
  type        = string
  default     = "eu-west-1b"
}

# ============================================
# EKS Variables
# ============================================
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"

  # INTERVIEW TIP: "We chose t3.medium as a balance between 
  # cost and resources. For production, we'd consider m5.large 
  # or use multiple instance types with mixed instances policy"
}

variable "node_desired_size" {
  description = "Desired number of nodes per node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes per node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes per node group"
  type        = number
  default     = 4
}
