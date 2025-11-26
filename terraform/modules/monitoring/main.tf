# Monitoring Module - Prometheus + Grafana Stack
# Deploys kube-prometheus-stack via Helm

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

resource "random_password" "grafana_admin_password" {
  length           = 16
  special          = false # Explicitly disable the inclusion of special characters
  override_special = false # Ensures 'special' setting is not overridden by other arguments

  # Recommended for stronger security: Ensure a mix of character types
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1

  # Optional: Keep it simple if you are fine with the default
  # min_length_upper, min_length_lower, and min_length_numeric
  # default to 0 if 'special' is false, but setting them > 0 is best practice.
}

# Deploy kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          resources = {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          # Service monitor selector - scrape all ServiceMonitors
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          # Additional scrape configs for pod annotations
          additionalScrapeConfigs = [
            {
              job_name = "kubernetes-pods"
              kubernetes_sd_configs = [
                {
                  role = "pod"
                }
              ]
              relabel_configs = [
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                  action        = "keep"
                  regex         = "true"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                  action        = "replace"
                  target_label  = "__metrics_path__"
                  regex         = "(.+)"
                },
                {
                  source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                  action        = "replace"
                  regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                  replacement   = "$1:$2"
                  target_label  = "__address__"
                },
                {
                  action = "labelmap"
                  regex  = "__meta_kubernetes_pod_label_(.+)"
                },
                {
                  source_labels = ["__meta_kubernetes_namespace"]
                  action        = "replace"
                  target_label  = "namespace"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_name"]
                  action        = "replace"
                  target_label  = "pod"
                }
              ]
            }
          ]
        }
        service = {
          type     = var.service_type
          nodePort = var.service_type == "NodePort" ? 30090 : null
        }
      }
      grafana = {
        enabled       = true
        adminPassword = random_password.grafana_admin_password.result
        persistence = {
          enabled = true
          size    = var.grafana_storage_size
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
        service = {
          type     = var.service_type
          nodePort = var.service_type == "NodePort" ? 30030 : null
        }
        # Pre-configure Prometheus datasource
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name      = "Prometheus"
                type      = "prometheus"
                url       = "http://kube-prometheus-stack-prometheus:9090"
                isDefault = true
              }
            ]
          }
        }
      }
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          resources = {
            requests = {
              memory = "128Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
      # Node exporter for node metrics
      nodeExporter = {
        enabled = true
      }
      # Kube state metrics
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  timeout = 600

  depends_on = [kubernetes_namespace.monitoring]
}

# ServiceMonitor for tech-challenge application
# Note: If your app exposes Prometheus metrics at /metrics, you can create
# a ServiceMonitor after the initial deployment using kubectl:
#
# kubectl apply -f - <<EOF
# apiVersion: monitoring.coreos.com/v1
# kind: ServiceMonitor
# metadata:
#   name: tech-challenge-app-monitor
#   namespace: tech-challenge
#   labels:
#     app: tech-challenge-app
#     release: kube-prometheus-stack
# spec:
#   selector:
#     matchLabels:
#       app: tech-challenge-app
#   endpoints:
#   - port: http
#     path: /metrics
#     interval: 30s
# EOF
#
# MongoDB already has ServiceMonitor enabled through the exporter below

# MongoDB Exporter for MongoDB metrics
resource "helm_release" "mongodb_exporter" {
  name       = "mongodb-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-mongodb-exporter"
  version    = "3.5.0"
  namespace  = var.app_namespace

  values = [
    yamlencode({
      mongodb = {
        uri = var.mongodb_uri
      }
      serviceMonitor = {
        enabled = true
        additionalLabels = {
          release = "kube-prometheus-stack"
        }
      }
      resources = {
        requests = {
          memory = "64Mi"
          cpu    = "50m"
        }
        limits = {
          memory = "128Mi"
          cpu    = "200m"
        }
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}
