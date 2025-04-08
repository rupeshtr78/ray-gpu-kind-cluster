# GPU-Accelerated Kubernetes Ray Clusters on Kind

Deploy Ray clusters and GPU-enabled containers on Kubernetes using Kind, NVIDIA GPU support, and the KubeRay operator.

---

## Repository Structure & Key Components

### Main Components:

- **kind-gpu-cluster/**

  - Scripts and YAML manifests to quickly deploy and test GPU-enabled KIND (Kubernetes IN Docker) clusters.
  - Provides integration scripts to leverage NVIDIA GPUs in local Kubernetes environments.

- **ray-cluster/**

  - Dockerfiles and YAML manifests for building and deploying Ray clusters.
  - Scripts to launch and manage Ray clusters and Ray jobs.
  - Ray job scripts (`qwen2_serve.py`, `qwen2_run.py`, etc.) to deploy and test inference workloads using Qwen2 and other LLM models.

- **ray-oss-chart/**

  - Reference Helm charts to deploy Ray clusters (`ray-cluster/`), the KubeRay Operator (`kuberay-operator/`), and the KubeRay API server (`kuberay-apiserver/`).

---

## Prerequisites

Before you start, ensure you have:

- Kubernetes (Kind recommended for local setups)
- Docker
- Helm v3
- NVIDIA GPU drivers and `nvidia-container-runtime` installed on the host (for GPU-enabled workloads)
- Ray CLI
- Python dependencies listed in the respective `Dockerfile` and Python script folders

---

## Quick Start

### 1. Set Up a GPU-Enabled KIND Cluster Deploy Ray Cluster & Operators

Deploy a local Kubernetes cluster including NVIDIA GPU support:

```bash
kind-gpu-cluster/kind/create-cluster.sh
```

Check NVIDIA GPUs availability in your KIND cluster:

```bash
kubectl apply -f ../../gpu-test.yaml
kubectl get pods
```

### 2. Deploy your Ray cluster:

```bash
 ray-cluster/ray-cluster.sh
```

### 3. Run GPU-Accelerated Ray Jobs

Build the Ray Cluster Docker image (with Qwen2 support):

```bash
cd ray-cluster
docker run -d -p 5050:5000 --restart=always --name registry registry:2
docker build -t 10.0.0.213:5050/qwen2-serve-ray:1.0.4 .
docker push 10.0.0.213:5050/qwen2-serve-ray:1.0.4
```

### Deploy Ray jobs

```bash
# logs will show the Ray cluster's total resource capacity, including GPUs.
ray job submit --address http://localhost:8265 -- python -c "import pprint; import ray; ray.init(); pprint.pprint(ray.cluster_resources(), sort_dicts=True)"
```

### Port Forward

Port forward ports 8265 and 8000

### Ray Serve (example Qwen2 inference):

```bash

ray job submit \
    --address http://localhost:8265 \
    --working-dir ./ray-cluster/ray-jobs \
    --runtime-env-json='{"pip":["torch", "transformers", "ray[serve]", "starlette"]}' \
    -- python qwen2_run.py

```

Inference

```
curl -X POST http://127.0.0.1:9023/
     -H "Content-Type: application/json" \
     -d '{"prompt": "Explain the concept of Apache ray", "max_new_tokens": 100}'
```

## Repository Map & Important Files Overview

- `kind-gpu-cluster/`: KIND GPU enabled cluster creation scripts, NVIDIA plugins setup, GPU tests, and other utilities.
- `ray-cluster/Dockerfile`: Docker image specification to run GPU workloads on a Ray cluster.
- `ray-cluster/ray-jobs/`: Sample Python scripts including Ray workloads and functionalities (`qwen2_serve.py`, `qwen2_run.py`, `check_resources.py`, etc.).
- `ray-oss-chart/kuberay-*`: For reference KubeRay operator and API server Helm charts for Ray cluster orchestration.

---

## Customizations

- Extend the Ray jobs by editing scripts in the `ray-cluster/ray-jobs/` directory.
- Configure your Ray clusters and deployments through respective Helm chart `values.yaml`.
- Modify GPU Kind clusters' configuration on the kernel and Nvidia plugins in `kind-gpu-cluster`.

---

## Contributions and Issues

Contributions, suggestions, and bug reports are always welcome! Feel free to open a pull request or submit an issue if you encounter any problems.
