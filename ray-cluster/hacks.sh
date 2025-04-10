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

# build and push to local registry
docker build -t 10.0.0.213:5050/qwen2-serve-ray:1.0.3 .

ray job submit --address http://localhost:8265 -- python /home/ray/app/check_resources.py 

ray job submit --address http://localhost:8265 -- python app/check_resources.py #  also works



# worked
serve run --address http://localhost:8265 --working-dir /home/ray/app qwen2_serve:qwen_server # this worked 1.0.1

curl -X POST http://127.0.0.1:9023 \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Explain the concept of Apache ray", "max_new_tokens": 100}'

curl -X POST http://127.0.0.1:9023/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Explain the concept of Apache ray", "max_new_tokens": 1000}'


# working
ray job submit \
    --address http://localhost:8265 \
    --working-dir ./ray-cluster/ray-jobs \
    --runtime-env-json='{"pip":["torch", "transformers", "ray[serve]", "starlette"]}' \
    -- python qwen2_run.py


ray job stop 09000000 --address http://localhost:8265

serve run --address http://localhost:8265 app.qwen2_serve:qwen_server # not working


helm uninstall raycluster -n ray-cluster


# stop the serve
ray job submit --address http://localhost:8265 -- python -c "import ray; from ray import serve; ray.init(address="auto"); serve.delete('Qwen25Server')"

# Ray Client (default port 10001)
# Ray Dashboard (default port 8265)
# Ray GCS server (default port 6379)
# Ray Serve (default port 8000)
# Ray Prometheus metrics (default port 8080)