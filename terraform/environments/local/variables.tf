# Environment and Project Configuration
variable "environment" {
  description = "Environment name (e.g., local, dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Minikube Connection Configuration
variable "minikube_host" {
  description = "Minikube cluster host IP"
  type        = string
}

variable "minikube_port" {
  description = "Minikube cluster port"
  type        = string
}

variable "minikube_client_certificate" {
  description = "Base64 encoded client certificate for Minikube"
  type        = string
  sensitive   = true
}

variable "minikube_client_key" {
  description = "Base64 encoded client key for Minikube"
  type        = string
  sensitive   = true
}

variable "minikube_ca_certificate" {
  description = "Base64 encoded CA certificate for Minikube"
  type        = string
  sensitive   = true
}

# Application Configuration
variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 1
}

# MongoDB Configuration
variable "mongodb_storage_size" {
  description = "Storage size for MongoDB PersistentVolume"
  type        = string
}

variable "mongodb_root_username" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring stack"
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
  default     = "5Gi"
}
