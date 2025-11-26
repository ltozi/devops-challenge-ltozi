# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., local, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "tech-challenge"
}

# Application Configuration
variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
}

variable "app_service_type" {
  description = "Kubernetes service type for the application (e.g., NodePort, LoadBalancer)"
  type        = string
}

# MongoDB Configuration
variable "mongodb_storage_size" {
  description = "MongoDB persistent volume size"
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
  default     = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus persistent volume"
  type        = string
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana persistent volume"
  type        = string
}
