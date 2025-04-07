#!/bin/bash

# Set variables
RELEASE_NAME="raycluster"
HELM_REPO_NAME="kuberay"
HELM_CHART="ray-cluster"
HELM_CHART_VERSION="1.3.0"
NAMESPACE="ray-cluster"
VALUES_FILE="ray-cluster-values.yaml"

# Add Helm repository if not exist
helm repo add "${HELM_REPO_NAME}" https://ray-project.github.io/kuberay-helm/
helm repo update

# Create namespace if doesn't exist and install Ray cluster 
helm upgrade --install "${RELEASE_NAME}" "${HELM_REPO_NAME}/${HELM_CHART}" \
  --version "${HELM_CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}"

# Optionally wait until all pods are ready
echo "Waiting for Ray cluster pods to be ready..."
kubectl wait --for=condition=ready pod -l ray.io/cluster="${RELEASE_NAME}" -n "${NAMESPACE}" --timeout=300s

# Check the Ray cluster pods
kubectl get pods --selector=ray.io/cluster=raycluster-kuberay -n "${NAMESPACE}"

export HEAD_POD=$(kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)
echo $HEAD_POD

kubectl get service raycluster-kuberay-head-svc -n "${NAMESPACE}"