# ============================================
# EKS Cluster
# ============================================
# WHY EKS?
# - Managed Kubernetes - AWS handles control plane
# - High availability built-in
# - Native AWS integrations (IAM, VPC, ALB, etc.)
# - No need to manage etcd, API server, scheduler
#
# INTERVIEW TIP: "EKS is managed Kubernetes. AWS handles 
# the control plane (API server, etcd, scheduler) so we 
# only manage the worker nodes. This reduces operational 
# overhead significantly."
#
# COST: ~$0.10/hour for control plane + node costs

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public.id,
      aws_subnet.private.id
    ]

    # Best practice: disable public endpoint in production
    endpoint_public_access  = true
    endpoint_private_access = true

    # Security groups for cluster
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  # Enable logging for debugging/auditing
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  tags = {
    Name = "${var.project_name}-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ============================================
# Security Group for EKS Cluster
# ============================================
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

# ============================================
# EKS Node Group - Public Subnet
# ============================================
# WHY Node Group in Public Subnet?
# - Assignment requirement
# - In real world, we usually put nodes in private subnet
# - Public node groups can be useful for specific use cases
#
# INTERVIEW TIP: "For production, we'd typically place 
# all nodes in private subnets and expose services only 
# through a Load Balancer or Ingress. But the assignment 
# asks for nodes in both subnets."

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-public-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.public.id]

  # Instance configuration
  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"  # Could use SPOT for cost savings

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Use latest EKS-optimized AMI
  ami_type = "AL2_x86_64"

  labels = {
    "node-type" = "public"
    "env"       = var.environment
  }

  tags = {
    Name = "${var.project_name}-public-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}

# ============================================
# EKS Node Group - Private Subnet
# ============================================
# WHY Node Group in Private Subnet?
# - More secure - no direct internet access
# - Uses NAT Gateway for outbound traffic
# - Best practice for workloads

resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-private-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.private.id]

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  ami_type = "AL2_x86_64"

  labels = {
    "node-type" = "private"
    "env"       = var.environment
  }

  tags = {
    Name = "${var.project_name}-private-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}

# ============================================
# EKS Add-ons
# ============================================
# These are essential components for EKS

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  # INTERVIEW TIP: "VPC CNI is the networking plugin that 
  # assigns VPC IP addresses directly to pods. This allows 
  # pods to communicate with other AWS services natively."
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [
    aws_eks_node_group.public,
    aws_eks_node_group.private
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}
