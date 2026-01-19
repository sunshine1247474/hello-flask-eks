# ============================================
# VPC - Virtual Private Cloud
# ============================================
# WHY VPC?
# - Network isolation for security
# - Control over IP addressing
# - Subnet segmentation (public/private)
#
# INTERVIEW TIP: "VPC is our isolated network in AWS. We use 
# public subnets for internet-facing resources and private 
# subnets for internal workloads that shouldn't be directly 
# accessible from the internet."

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Required for EKS
  enable_dns_support   = true  # Required for EKS

  tags = {
    Name = "${var.project_name}-vpc"
    # These tags are required for EKS to discover the VPC
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }
}

# ============================================
# Internet Gateway
# ============================================
# WHY IGW?
# - Allows resources in public subnets to reach the internet
# - Allows internet traffic to reach public resources
#
# INTERVIEW TIP: "IGW is like the front door of our VPC. 
# Without it, nothing can communicate with the internet."

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ============================================
# Public Subnet
# ============================================
# WHY PUBLIC SUBNET?
# - For Load Balancers (internet-facing)
# - For NAT Gateway
# - Assignment requires node group here
#
# INTERVIEW TIP: "Resources in public subnet get public IPs 
# and can be reached from internet. We minimize what goes here."

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = {
    Name = "${var.project_name}-public-subnet"
    # Required tags for EKS to use this subnet for Load Balancers
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }
}

# ============================================
# Private Subnet
# ============================================
# WHY PRIVATE SUBNET?
# - For application workloads (more secure)
# - No direct internet access
# - Assignment requires node group here
#
# INTERVIEW TIP: "Private subnet resources have no public IP 
# and can't be reached from internet. This is security best 
# practice for application workloads."

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.project_name}-private-subnet"
    # Required tags for EKS to use this subnet for internal Load Balancers
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }
}

# ============================================
# Elastic IP for NAT Gateway
# ============================================
# WHY EIP?
# - NAT Gateway needs a static public IP
# - Allows tracking/whitelisting outbound traffic
#
# COST TIP: EIP costs ~$3.65/month when not attached

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================
# NAT Gateway
# ============================================
# WHY NAT Gateway?
# - Allows private subnet resources to reach internet (outbound only)
# - For pulling Docker images, updates, etc.
# - No inbound access from internet
#
# INTERVIEW TIP: "NAT Gateway allows our private resources 
# to make outbound connections (like pulling images from ECR) 
# while remaining unreachable from the internet."
#
# COST TIP: NAT Gateway costs ~$32/month + data processing
# Alternative: NAT Instance (cheaper but less reliable)

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id  # NAT must be in public subnet

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================
# Route Table - Public
# ============================================
# Routes traffic from public subnet to Internet Gateway

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Route Table - Private
# ============================================
# Routes traffic from private subnet through NAT Gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
