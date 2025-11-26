#!/bin/bash
# Script to set up dynamic Terraform environment variables for local Minikube
# and run terraform commands
# 
# Usage:
#   ./tf-local.sh plan             # Export dynamic vars and run terraform plan
#   ./tf-local.sh apply            # Export dynamic vars and run terraform apply
#   source ./tf-local.sh           # Just export the variables to current shell

# Check if minikube is running
if ! minikube status &>/dev/null 2>&1; then
    echo "❌ Minikube is not running. Start it with: minikube start"
    return 1 2>/dev/null || exit 1
fi

echo "🔍 Extracting Minikube connection details..."

# Get API server URL and parse
API_URL=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.server}')
API_HOST=$(echo "$API_URL" | sed -E 's|https?://([^:]+):.*|\1|')
API_PORT=$(echo "$API_URL" | grep -oE '[0-9]+$')

# Get certificate file paths
CA_FILE=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.certificate-authority}')
CLIENT_CERT_FILE=$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="minikube")].user.client-certificate}')
CLIENT_KEY_FILE=$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="minikube")].user.client-key}')

# Read and base64 encode certificates
CA_CERT=$(cat "$CA_FILE" | base64 | tr -d '\n')
CLIENT_CERT=$(cat "$CLIENT_CERT_FILE" | base64 | tr -d '\n')
CLIENT_KEY=$(cat "$CLIENT_KEY_FILE" | base64 | tr -d '\n')

echo "✓ Connected to Minikube at $API_HOST:$API_PORT"
echo ""

# Export Minikube connection variables dynamically
export TF_VAR_minikube_host="$API_HOST"
export TF_VAR_minikube_port="$API_PORT"
export TF_VAR_minikube_ca_certificate="$CA_CERT"
export TF_VAR_minikube_client_certificate="$CLIENT_CERT"
export TF_VAR_minikube_client_key="$CLIENT_KEY"

echo "📝 Exported dynamic environment variables:"
echo "   TF_VAR_minikube_host=$API_HOST"
echo "   TF_VAR_minikube_port=$API_PORT"
echo "   TF_VAR_minikube_ca_certificate=<base64-encoded>"
echo "   TF_VAR_minikube_client_certificate=<base64-encoded>"
echo "   TF_VAR_minikube_client_key=<base64-encoded>"
echo ""

# If script was sourced, just set vars. If executed, run terraform
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script was executed, not sourced
    if [ $# -eq 0 ]; then
        echo "💡 Dynamic variables exported. You can now run terraform commands like:"
        echo "   terraform plan -var-file=terraform-local.tfvars"
        echo "   terraform apply -var-file=terraform-local.tfvars"
        echo ""
        echo "   Or run this script with terraform commands:"
        echo "   ./tf-local.sh plan"
        echo "   ./tf-local.sh apply"
    else
        echo "🚀 Running: terraform $@ -var-file=terraform-local.tfvars"
        echo ""
        terraform "$@" -var-file=terraform-local.tfvars
    fi
else
    # Script was sourced
    echo "✓ Variables exported to current shell. Ready to run terraform commands!"
fi
