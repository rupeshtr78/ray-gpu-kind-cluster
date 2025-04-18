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
HOST_IP="10.0.0.213"

# # Extract Ray Head Pod Name
HEAD_POD=$(kubectl get pods \
  --selector="ray.io/node-type=head" \
  -n "${NAMESPACE}" \
  -o jsonpath='{.items[0].metadata.name}')

echo $HEAD_POD
echo "🚀 Port forwarding to Ray Head Pod..."

# Forward 8265 Ray Dashboard
kubectl port-forward \
  --namespace "${NAMESPACE}" \
  "${HEAD_POD}" \
  --address "${HOST_IP}" \
  8265:8265 &

# Forward 10001 Ray Client
kubectl port-forward \
  --namespace "${NAMESPACE}" \
  "${HEAD_POD}" \
  --address "${HOST_IP}" \
  10001:10001 &

# Forward Ray Server 8000 to 9023
kubectl port-forward \
  --namespace "${NAMESPACE}" \
  "${HEAD_POD}" \
  --address "${HOST_IP}" \
  8000:9023 &

echo "🚀 Finished Port forwarding to Ray Head Pod..." 