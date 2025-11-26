terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }

  #   backend "s3" {
  #     bucket         = "your-terraform-state-bucket-aws" # Use a unique bucket for AWS state
  #     key            = "tech-challenge/terraform.tfstate"
  #     region         = "eu-south-1"
  #     encrypt        = true
  #     use_lockfile   = true
  #   }
}

# Configure providers
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "aws"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/networking"

  environment        = "aws"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  enable_nat_gateway = true
  single_nat_gateway = false # For production-like env
}

# EKS Cluster Module
module "eks" {
  source = "../../modules/eks"

  environment        = "aws"
  project_name       = var.project_name
  cluster_version    = var.k8s_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Node group configuration
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size
}

# Password Generation
resource "random_password" "mongodb_root_password" {
  length  = 16
  special = true
}

resource "random_password" "grafana_admin_password" {
  length  = 16
  special = true
}

# Deploy Kubernetes resources using the shared infra-stack module
module "infra_stack" {
  source = "../../modules/infra-stack"

  environment             = "aws"
  project_name            = var.project_name
  app_image               = var.app_image
  app_replicas            = var.app_replicas
  app_service_type        = "LoadBalancer"
  mongodb_storage_size    = var.mongodb_storage_size
  mongodb_root_username   = var.mongodb_root_username
  mongodb_root_password   = random_password.mongodb_root_password.result
  enable_monitoring       = var.enable_monitoring
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  grafana_admin_password  = random_password.grafana_admin_password.result

  depends_on = [
    module.eks
  ]
}
