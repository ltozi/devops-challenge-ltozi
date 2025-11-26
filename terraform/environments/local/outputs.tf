# Pass-through outputs from the infra-stack module
output "app_namespace" {
  description = "Kubernetes namespace for the application"
  value       = module.infra_stack.namespace
}

output "app_service_name" {
  description = "Application Kubernetes service name"
  value       = module.infra_stack.app_service_name
}

# Local-specific outputs
output "access_instructions" {
  description = "Instructions to access the application"
  value       = "Run 'minikube service ${module.infra_stack.app_service_name} -n ${module.infra_stack.namespace}'"
}

output "monitoring_access_instructions" {
  description = "Instructions to access Prometheus and Grafana"
  sensitive   = true
  value       = !var.enable_monitoring ? "Monitoring is disabled." : <<-EOT
  Prometheus: Run 'minikube service kube-prometheus-stack-prometheus -n monitoring' (Port: 30090)
  Grafana: Run 'minikube service kube-prometheus-stack-grafana -n monitoring' (Port: 30030)
  EOT
}

output "service_credentials" {
  description = "Map of service credentials"
  sensitive   = true
  value = {
    grafana = {
      user     = "admin"
      password = module.infra_stack.grafana_admin_password
    }
    mongodb = {
      user     = var.mongodb_root_username
      password = module.infra_stack.mongo_admin_password
    }
  }
}