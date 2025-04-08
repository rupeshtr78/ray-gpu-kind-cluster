#!/bin/bash
set -e

CURRENT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

# Constants
RELEASE_NAME="raycluster"
HELM_REPO_NAME="kuberay"
HELM_CHART="ray-cluster"
HELM_CHART_VERSION="1.3.0"
HELM_REPO_URL="https://ray-project.github.io/kuberay-helm/"
NAMESPACE="ray-cluster"
VALUES_FILE="${CURRENT_DIR}/ray-cluster-values.yaml"
PVC_NAME="hf-cache-pvc"

# Ensure Helm Repo is added
if ! helm repo list | grep -q "^${HELM_REPO_NAME}\b"; then
  echo "📥 Adding ${HELM_REPO_NAME} Helm repository..."
  helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}"
  helm repo update
fi

# Create namespace if it doesn't exist
if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  echo "📥 Creating namespace ${NAMESPACE}..."
  kubectl create namespace "${NAMESPACE}"
fi

# Apply PVC Yif pvc if it doesn't exist
if ! kubectl get pvc "${PVC_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  echo "📥 Creating PVC ${PVC_NAME} in namespace ${NAMESPACE}..."
  kubectl apply -f - <<EOF
echo "📥 Applying PVC ${PVC_NAME} in namespace ${NAMESPACE}..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
  namespace: ${NAMESPACE}
spec:
  storageClassName: standard
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
fi

# Helm Deploy or Upgrade Ray Cluster
echo "🚀 Deploying Ray Cluster via Helm to namespace ${NAMESPACE}..."
helm upgrade --install "${RELEASE_NAME}" "${HELM_REPO_NAME}/${HELM_CHART}" \
  --version "${HELM_CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  --values "${VALUES_FILE}" \
  --wait \
  --timeout 600s

# Wait until all Ray pods are ready
# echo "⏳ Waiting for Ray Cluster pods to become ready (timeout: 300s)..."
# kubectl wait --for=condition=ready pod \
#   -l "ray.io/cluster=${RELEASE_NAME}" \
#   -n "${NAMESPACE}" \
#   --timeout=300s

# Display Ray Cluster pods after readiness
# echo "✅ Ray cluster pods status:"
# kubectl get pods -l "ray.io/cluster=${RELEASE_NAME}" -n "${NAMESPACE}"

# # Extract Ray Head Pod Name
# HEAD_POD=$(kubectl get pods \
#   --selector="ray.io/cluster=${RELEASE_NAME},ray.io/node-type=head" \
#   -n "${NAMESPACE}" \
#   -o jsonpath='{.items[0].metadata.name}')

# if [[ -z "${HEAD_POD}" ]]; then
#   echo "❌ Head pod not found."
#   exit 1
# else
#   echo "🎯 Head Pod of Ray Cluster: ${HEAD_POD}"
# fi

# Display Ray Cluster head service
echo "📡 Ray Cluster Head service details:"
kubectl get service "${RELEASE_NAME}-head-svc" -n "${NAMESPACE}"