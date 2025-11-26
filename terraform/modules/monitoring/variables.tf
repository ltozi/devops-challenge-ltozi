variable "app_namespace" {
  description = "Namespace where the application is deployed"
  type        = string
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus persistent volume"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana persistent volume"
  type        = string
  default     = "5Gi"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI for MongoDB exporter"
  type        = string
  sensitive   = true
}

variable "service_type" {
  description = "Service type for Prometheus and Grafana (NodePort for local, LoadBalancer for AWS)"
  type        = string
  default     = "NodePort"
  validation {
    condition     = contains(["NodePort", "LoadBalancer", "ClusterIP"], var.service_type)
    error_message = "Service type must be NodePort, LoadBalancer, or ClusterIP"
  }
}
