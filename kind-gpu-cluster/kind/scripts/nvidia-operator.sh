#!/bin/bash
set -euo pipefail

# Variables
RELEASE_NAME=${RELEASE_NAME:-gpu-operator}
NAMESPACE=${NAMESPACE:-gpu-operator}
HELM_REPO_NAME=${HELM_REPO_NAME:-nvidia}
HELM_CHART=${HELM_CHART:-gpu-operator}
DRIVER_ENABLED=${DRIVER_ENABLED:-false}

# Ensure NVIDIA Helm repo is added
if ! helm repo list | grep -q "^${HELM_REPO_NAME}\b"; then
  echo "📥 Adding ${HELM_REPO_NAME} Helm repository..."
  helm repo add "${HELM_REPO_NAME}" https://helm.ngc.nvidia.com/nvidia
  helm repo update
fi

# Create namespace (if it doesn't already exist)
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || {
  echo "📦 Namespace '${NAMESPACE}' not found. Creating it now..."
  kubectl create namespace "${NAMESPACE}"
}

echo "🚀 Installing/Upgrading NVIDIA GPU Operator in namespace '${NAMESPACE}'..."

helm upgrade --install "${RELEASE_NAME}" "${HELM_REPO_NAME}/${HELM_CHART}" \
  --namespace "${NAMESPACE}" \
  --set driver.enabled="${DRIVER_ENABLED}" \
  --wait \
  --timeout 10m

echo "✅ NVIDIA GPU Operator successfully installed/upgraded."