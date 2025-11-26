variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "app_image" {
  description = "Docker image for application"
  type        = string
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
}

variable "app_service_type" {
  description = "Kubernetes service type for application (NodePort or LoadBalancer)"
  type        = string
}

variable "mongodb_storage_size" {
  description = "MongoDB persistent volume size"
  type        = string
}

variable "mongodb_root_username" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
}

