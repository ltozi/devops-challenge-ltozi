# Pass-through outputs from the infra-stack module
output "app_namespace" {
  description = "Kubernetes namespace for the application"
  value       = module.infra_stack.namespace
}

output "app_service_name" {
  description = "Application Kubernetes service name"
  value       = module.infra_stack.app_service_name
}

# AWS-specific outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# Access instructions
output "access_instructions" {
  description = "Instructions to access the application"
  value       = "Run 'kubectl get svc ${module.infra_stack.app_service_name} -n ${module.infra_stack.namespace}' to get the LoadBalancer URL."
}

output "monitoring_access_instructions" {
  description = "Instructions to access Prometheus and Grafana"
  sensitive   = true
  value       = !var.enable_monitoring ? "Monitoring is disabled." : <<-EOT
  Prometheus: Run 'kubectl get svc kube-prometheus-stack-prometheus -n monitoring'
  Grafana: Run 'kubectl get svc kube-prometheus-stack-grafana -n monitoring'
  Grafana credentials: admin / ${random_password.grafana_admin_password.result}
  EOT
}

output "service_credentials" {
  description = "Map of service credentials"
  sensitive   = true
  value = {
    grafana = {
      user     = "admin"
      password = random_password.grafana_admin_password.result
    }
    mongodb = {
      user     = var.mongodb_root_username
      password = random_password.mongodb_root_password.result
    }
  }
}
