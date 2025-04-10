.PHONY: all kind gpu-test build-image deploy-ray port-forward submit-job deploy-qwen2 inference clean

# Change these configs
IMAGE_TAG ?= 10.0.0.213:5050/qwen2-serve-ray:1.0.5
REGISTRY_NAME ?= registry
REGISTRY_PORT ?= 5050
CLUSTER_SCRIPT = kind-gpu-cluster/kind/create-cluster.sh
RAY_CLUSTER_SCRIPT = ray-cluster/ray-cluster.sh

all: kind gpu-test build-image deploy-ray port-forward submit-job

## 1: Create KIND GPU Cluster, Deploy GPU operator & Ray operator
kind:
	bash $(CLUSTER_SCRIPT)

## Check GPU availability in cluster
gpu-test:
	kubectl apply -f kind-gpu-cluster/gpu-test.yaml

## Docker build and push Ray cluster image
build-image:
	# cd ray-cluster && \
	# docker run -d -p $(REGISTRY_PORT):5000 --restart=always --name $(REGISTRY_NAME) registry:2 || true
	cd ray-cluster && \
	docker build -t $(IMAGE_TAG) . && \
	docker push $(IMAGE_TAG)

## Deploy Ray cluster resources
ray-deploy:
	bash $(RAY_CLUSTER_SCRIPT)

## Port-forward Ray dashboard (8265) and API (8000)
port-forward:
	kubectl port-forward svc raycluster-kuberay-head-svc 8265:8265 9023:8000 --address=0.0.0.0 &

## Submit a simple job to Ray to test the cluster
submit-job:
	ray job submit --address http://localhost:8265 \
	-- python -c "import pprint; import ray; ray.init(); pprint.pprint(ray.cluster_resources(), sort_dicts=True)"

## Deploy Qwen2 Ray Serve Model
deploy-qwen2:
	ray job submit \
		--address http://localhost:8265 \
		--working-dir ./ray-cluster/ray-jobs \
		--runtime-env-json='{"pip":["torch","transformers","ray[serve]","starlette"]}' \
		-- python qwen2_run.py

## Test inference API for Qwen2
inference:
	curl -X POST http://127.0.0.1:9023/ \
	-H "Content-Type: application/json" \
	-d '{"prompt": "Explain the concept of Apache Ray", "max_new_tokens": 100}'

# Uninstall ray cluster
ray-delete:
		helm uninstall raycluster -n ray-cluster

## Cleanup
kind-delete:
	kind delete cluster
	docker rm -f $(REGISTRY_NAME) || true