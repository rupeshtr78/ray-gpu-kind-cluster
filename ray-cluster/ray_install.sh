#!/bin/bash
#

helm install kuberay-operator kuberay/kuberay-operator --version 1.3.0 \
     -n kuberay-operator --create-namespace \
     --values ray-operator-values.yaml

# Create a RayCluster Custom Resource (CR) in the default namespace.
helm install raycluster kuberay/ray-cluster --version 1.3.0 \
     -n ray-cluster --create-namespace \
     --values ray-cluster-values.yaml

helm uninstall raycluster --namespace ray-cluster

# View the pods in the RayCluster named "raycluster-kuberay"
kubectl get pods --selector=ray.io/cluster=raycluster-kuberay


# Print the cluster resources.
kubectl exec -it $HEAD_POD -- python -c "import pprint; import ray; ray.init(); pprint.pprint(ray.cluster_resources(), sort_dicts=True)"

# The following job's logs will show the Ray cluster's total resource capacity, including 2 CPUs.
ray job submit --address http://localhost:8265 -- python -c "import pprint; import ray; ray.init(); pprint.pprint(ray.cluster_resources(), sort_dicts=True)"

kind get nodes --name k8s-device-plugin-cluster # without kind- prefix

kind load docker-image my-ray-image:v1 --name k8s-device-plugin-cluster

kubectl get nodes -o wide
docker exec -it kind-control-plane crictl images | grep my-ray-image