terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # AWS provider is not strictly required for local, but kept for consistency
    # It will not be configured or used.
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
  }

  # For local, we use local state.
  # A backend block could be configured for a shared local env if needed.
}

# Configure providers for Minikube
provider "kubernetes" {
  host                   = "https://${var.minikube_host}:${var.minikube_port}"
  client_certificate     = base64decode(var.minikube_client_certificate)
  client_key             = base64decode(var.minikube_client_key)
  cluster_ca_certificate = base64decode(var.minikube_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${var.minikube_host}:${var.minikube_port}"
    client_certificate     = base64decode(var.minikube_client_certificate)
    client_key             = base64decode(var.minikube_client_key)
    cluster_ca_certificate = base64decode(var.minikube_ca_certificate)
  }
}

# Deploy Kubernetes resources using the shared infra-stack module
module "infra_stack" {
  source = "../../modules/infra-stack"

  environment             = "local"
  project_name            = var.project_name
  app_image               = var.app_image
  app_replicas            = var.app_replicas
  app_service_type        = "NodePort"
  mongodb_storage_size    = var.mongodb_storage_size
  mongodb_root_username   = var.mongodb_root_username
  enable_monitoring       = var.enable_monitoring
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
}
