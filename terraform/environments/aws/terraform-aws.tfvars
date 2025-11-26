# AWS Environment Configuration (EKS)
environment  = "aws"
project_name = "tech-challenge"
aws_region   = "us-east-1" # Change to your preferred region
k8s_version  = "1.28"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# EKS Node Group Configuration
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3
node_disk_size      = 20

# Application Configuration
app_image    = "tech-challenge-app:latest" # Update with ECR URL: 123456789.dkr.ecr.us-east-1.amazonaws.com/tech-challenge-app:latest
app_replicas = 3                           # High availability

# MongoDB Configuration
mongodb_storage_size  = "10Gi"
mongodb_root_username = "root"
