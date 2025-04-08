# Ray Cluster GPU Deployment Repository

Deploy Ray clusters and GPU-enabled containers on Kubernetes using Kind, NVIDIA GPU support, and the KubeRay operator.

---

## Repository Structure & Key Components

### Main Components:

- **ray-cluster/**

  - Dockerfiles and YAML manifests for building and deploying Ray clusters.
  - Scripts to launch and manage Ray clusters and Ray jobs.
  - Ray job scripts (`qwen2_serve.py`, `qwen2_run.py`, etc.) to deploy and test inference workloads using Qwen2 and other LLM models.

- **kind-gpu-cluster/**

  - Scripts and YAML manifests to quickly deploy and test GPU-enabled KIND (Kubernetes IN Docker) clusters.
  - Provides integration scripts to leverage NVIDIA GPUs in local Kubernetes environments.

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

### 1. Set Up a GPU-Enabled KIND Cluster

Deploy a local Kubernetes cluster including NVIDIA GPU support:

```bash
cd kind-gpu-cluster/kind/scripts
./create-kind-cluster.sh
./build-plugin-image.sh
./install-plugin.sh
```

Check NVIDIA GPUs availability in your KIND cluster:

```bash
kubectl apply -f ../../gpu-test.yaml
kubectl get pods
```

### 2. Deploy Ray Cluster & Operators

Deploy the KubeRay Operator and APIs using chart templates:

```bash
helm install kuberay-operator ./ray-oss-chart/kuberay-operator
helm install kuberay-apiserver ./ray-oss-chart/kuberay-apiserver
```

Then deploy your Ray cluster:

```bash
helm install my-ray-cluster ./ray-oss-chart/ray-cluster -f ray-cluster/ray-cluster-values.yaml
```

### 3. Run GPU-Accelerated Ray Jobs

Build the Ray Cluster Docker image (with Qwen2 support):

```bash
cd ray-cluster
docker build -t ray-cluster-gpu -f Dockerfile .
```

Deploy Ray jobs (example Qwen2 inference):

```bash
kubectl exec -it <ray-head-pod-name> -- /bin/bash
python ray-jobs/qwen2_serve.py
```

Alternatively, run GPU inference directly:

```bash
python ray-jobs/qwen2_run.py
```

---

## Repository Map & Important Files Overview

- `ray-cluster/Dockerfile`: Docker image specification to run GPU workloads on a Ray cluster.
- `ray-cluster/ray-jobs/`: Python scripts including Ray workloads and functionalities (`qwen2_serve.py`, `qwen2_run.py`, `check_resources.py`, etc.).
- `ray-oss-chart/kuberay-*`: KubeRay operator and API server Helm charts for Ray cluster orchestration.
- `kind-gpu-cluster/`: KIND GPU enabled cluster creation scripts, NVIDIA plugins setup, GPU tests, and other utilities.

---

## Advanced Development & Customizations

- Extend the Ray jobs by editing scripts in the `ray-cluster/ray-jobs/` directory.
- Configure your Ray clusters and deployments through respective Helm chart `values.yaml`.
- Modify GPU Kind clusters' configuration on the kernel and Nvidia plugins in `kind-gpu-cluster`.

---

## Contributions and Issues

Contributions, suggestions, and bug reports are always welcome! Feel free to open a pull request or submit an issue if you encounter any problems.
