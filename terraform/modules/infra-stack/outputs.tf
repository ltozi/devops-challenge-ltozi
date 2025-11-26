# Application Outputs
output "namespace" {
  description = "Kubernetes namespace"
  value       = module.k8s_resources.namespace
}

output "app_service_name" {
  description = "Application service name"
  value       = module.k8s_resources.app_service_name
}

output "app_service_type" {
  description = "Application service type"
  value       = module.k8s_resources.app_service_type
}

# Monitoring Outputs
output "prometheus_url" {
  description = "Prometheus service URL (cluster internal)"
  value       = var.enable_monitoring ? module.monitoring[0].prometheus_url : null
}

output "grafana_url" {
  description = "Grafana service URL (cluster internal)"
  value       = var.enable_monitoring ? module.monitoring[0].grafana_url : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.enable_monitoring ? module.monitoring[0].grafana_admin_password : null
  sensitive   = true
}

output "mongo_admin_password" {
  description = "Mongo admin password"
  value       = module.k8s_resources.mongodb_admin_password
  sensitive   = true
}