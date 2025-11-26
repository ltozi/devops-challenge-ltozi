# Network Policies for pod-to-pod communication control
# Implements zero-trust networking within the namespace

# Default Deny All Ingress Traffic
# This policy denies all ingress traffic to all pods in the namespace
# Specific policies below will allow only necessary traffic
resource "kubernetes_network_policy" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]
  }
}

# Default Deny All Egress Traffic
# This policy denies all egress traffic from all pods in the namespace
# Specific policies below will allow only necessary traffic
resource "kubernetes_network_policy" "default_deny_egress" {
  metadata {
    name      = "default-deny-egress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Egress"]
  }
}

# Allow Application to MongoDB
# Allows app pods to connect to MongoDB on port 27017
resource "kubernetes_network_policy" "app_to_mongodb" {
  metadata {
    name      = "app-to-mongodb"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.app_name
      }
    }

    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            app = local.mongo_name
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "27017"
      }
    }

    # Allow DNS resolution
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }
    }
  }
}

# Allow MongoDB Ingress from Application
# Allows MongoDB to receive connections from app pods only
resource "kubernetes_network_policy" "mongodb_from_app" {
  metadata {
    name      = "mongodb-from-app"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.mongo_name
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = local.app_name
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "27017"
      }
    }
  }
}

# Allow Application Ingress from External
# Allows external traffic to reach application pods on port 3000
resource "kubernetes_network_policy" "app_ingress" {
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.app_name
      }
    }

    policy_types = ["Ingress"]

    ingress {
      # Allow from anywhere (controlled by Service/LoadBalancer)
      ports {
        protocol = "TCP"
        port     = "3000"
      }
    }
  }
}

# Allow MongoDB Internal Communication
# Allows MongoDB pod to do internal operations
resource "kubernetes_network_policy" "mongodb_egress" {
  metadata {
    name      = "mongodb-egress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = local.mongo_name
      }
    }

    policy_types = ["Egress"]

    # Allow DNS resolution
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }
    }
  }
}
