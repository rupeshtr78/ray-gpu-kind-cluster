#!/bin/bash
set -euo pipefail

CURRENT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

# Variables
RELEASE_NAME=${RELEASE_NAME:-kuberay-operator}
NAMESPACE=${NAMESPACE:-kuberay-operator}
HELM_REPO_NAME=${HELM_REPO_NAME:-kuberay}
HELM_REPO_URL=${HELM_REPO_URL:-https://ray-project.github.io/kuberay-helm/}
HELM_CHART=${HELM_CHART:-kuberay-operator}
HELM_CHART_VERSION=${HELM_CHART_VERSION:-1.3.0}
VALUES_FILE=${VALUES_FILE:-${CURRENT_DIR}/ray-operator-values.yaml}

# Add KubeRay helm repository if not added already
if ! helm repo list | grep -q "^${HELM_REPO_NAME}\b"; then
  echo "📥 Adding ${HELM_REPO_NAME} Helm repository..."
  helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}"
  helm repo update
fi

# Create namespace if not existing
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || {
  echo "📦 Creating namespace '${NAMESPACE}'..."
  kubectl create namespace "${NAMESPACE}"
}

echo "🚀 Installing/upgrading KubeRay Operator (version ${HELM_CHART_VERSION}) in namespace '${NAMESPACE}'..."

helm upgrade --install "${RELEASE_NAME}" "${HELM_REPO_NAME}/${HELM_CHART}" \
  --version "${HELM_CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  --values "${VALUES_FILE}"

echo "✅ KubeRay Operator successfully installed/upgraded."