
variable "environment" {
  description = "The deployment environment (e.g., dev, stage, prod)"
  type        = string
  default     = "aws"
}

variable "project_name" {
  description = "Name of the project, used for tagging resources"
  type        = string
  default     = "tech-challenge"
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  description = "List of instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size (GB) for EKS worker nodes"
  type        = number
  default     = 20
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "tech-challenge-app:latest"
}

variable "app_replicas" {
  description = "Number of replicas for the application"
  type        = number
  default     = 3
}

variable "mongodb_storage_size" {
  description = "Storage size for MongoDB"
  type        = string
  default     = "10Gi"
}

variable "mongodb_root_username" {
  description = "Root username for MongoDB"
  type        = string
  default     = "root"
}

variable "enable_monitoring" {
  description = "Whether to enable monitoring (Grafana, Prometheus)"
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}
