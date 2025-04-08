# GPU-Passthrough Enabled Apache Ray Clusters on Kubernetes (Kind) for POC and Testing

Deploy Ray clusters and GPU-enabled containers on Kubernetes using Kind, NVIDIA GPU support, and the KubeRay operator. This setup allows GPU passthrough from your host system directly into your Kubernetes (Kind) cluster nodes, enabling GPU Ray workloads and serve deployments.

---

## Repository Structure & Key Components

### Main Components:

- **kind-gpu-cluster/**

  - Scripts and YAML manifests to quickly deploy and test GPU-enabled KIND (Kubernetes IN Docker) clusters.
  - scripts to leverage NVIDIA GPUs in local Kubernetes environments.

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

#### Mounting Hugging Face Cache from Host in Kubernetes Cluster

Mount Hugging Face cache directory from the host into your Ray cluster pods using PersistentVolume and PersistentVolumeClaim. This allows to reuse downloaded Hugging Face models, datasets, and other artifacts across pod restarts and deployments.

#### PersistentVolume Setup

The PersistentVolume is defined in [`kind-gpu-cluster/kind/scripts/hf-cache-pv/pv.yaml`](kind-gpu-cluster/kind/scripts/hf-cache-pv/pv.yaml), and it specifies a host directory to store Hugging Face cache:

```yaml
hostPath:
  path: /data/hf-cache
  type: Directory
```

This creates a PersistentVolume named `hf-cache-pv` associated with the host's `/data/hf-cache` directory. Adjust the `path` as needed based on the storage location on your Kubernetes host node.

#### Usage in Ray Helm Values

The Ray cluster Helm configuration (found in [`ray-cluster/ray-cluster-values.yaml`](ray-cluster/ray-cluster-values.yaml)) leverages the Hugging Face cache PV by referencing a PersistentVolumeClaim named `hf-cache-pvc`. Both the head node and worker nodes mount this volume:

```yaml
volumes:
  - name: hf-cache
    persistentVolumeClaim:
      claimName: hf-cache-pvc

volumeMounts:
  - name: hf-cache
    mountPath: /data/hf-cache
```

Furthermore, an environment variable `HUGGINGFACE_HUB_CACHE` explicitly points the Hugging Face library to use this mounted cache location directly:

```yaml
containerEnv:
  - name: HUGGINGFACE_HUB_CACHE
    value: /data/hf-cache/huggingface/hub
```

H

#### Mounting NVIDIA Drivers and Libraries into Kind Nodes

To enable GPU acceleration (including CUDA) inside a Kubernetes (`kind`) cluster, mount driver libraries and binaries from your host into the cluster nodes directly. The provided configuration file [`kind-gpu-cluster/kind/scripts/kind-cluster-config.yaml`](kind-gpu-cluster/kind/scripts/kind-cluster-config.yaml) ( Tried other options the /usr/lib/ is too big so had to choose specific files)

#### NVIDIA Libraries Mounting

Worker node definition (`role: worker`), NVIDIA driver-related libraries from `/usr/lib/x86_64-linux-gnu/` are explicitly mounted into containers to support GPU support:

```yaml
extraMounts:
  - containerPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.550.54.15
    hostPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.550.54.15
    readOnly: true
  # ...  NVIDIA libraries .....
```

This libraries helps GPU features, CUDA support.

#### GPU Driver Version

**match your mounted libraries with the host NVIDIA driver version** .I am running ubuntu 22.04 with driver version `550.54.15`. libraries and binaries must exactly match the host driver's installed version for compatibility and not hit runtime issues.

check that your host driver version matches exactly with the version number in the YAML:

## Start Deployment

#### 1. Set Up a GPU-Enabled KIND Cluster Deploy Nvidia device plugin , gpu operator & Ray Operators

This script deploys Kind Kubernetes cluster, configures the required host volume mounts including NVIDIA libraries and GPU device paths, creates Persistent Volumes (PV) and Persistent Volume Claims (PVC), and installs both the NVIDIA GPU Operator and KubeRay Operator

```bash
kind-gpu-cluster/kind/create-cluster.sh
```

Check NVIDIA GPUs availability in your KIND cluster:

```bash
kubectl apply -f gpu-test.yaml

```

#### 3. Docker image Build for Ray Cluster

[DockerFile](ray-cluster/Dockerfile)

```bash
cd ray-cluster
docker run -d -p 5050:5000 --restart=always --name registry registry:2
docker build -t 10.0.0.213:5050/qwen2-serve-ray:1.0.4 .
docker push 10.0.0.213:5050/qwen2-serve-ray:1.0.4
```

#### 4. Deploy your Ray cluster:

```bash
 ray-cluster/ray-cluster.sh
```

#### 5. Port Forward

Port forward ports 8265 and 8000

#### 5. Deploy Ray jobs

```bash
# logs will show the Ray cluster's total resource capacity, including GPUs.
ray job submit --address http://localhost:8265 -- python -c "import pprint; import ray; ray.init(); pprint.pprint(ray.cluster_resources(), sort_dicts=True)"
```

#### 7. Ray Serve (example Qwen2 inference):

```bash

ray job submit \
    --address http://localhost:8265 \
    --working-dir ./ray-cluster/ray-jobs \
    --runtime-env-json='{"pip":["torch", "transformers", "ray[serve]", "starlette"]}' \
    -- python qwen2_run.py

```

Inference

```
curl -X POST http://127.0.0.1:8000/
     -H "Content-Type: application/json" \
     -d '{"prompt": "Explain the concept of Apache ray", "max_new_tokens": 100}'
```

### Repository Map & Important Files Overview

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

## Documentation & References

- [Ray Documentation](https://docs.ray.io)
- [KubeRay Operator](https://github.com/ray-project/kuberay)
- [Kind Kubernetes](https://kind.sigs.k8s.io)
- [Nvidia Device Plugin](https://github.com/NVIDIA/k8s-device-plugin/tree/main) Kind build scripts refered from here.

## Contributions and Issues

Contributions, suggestions, and bug reports are always welcome! Feel free to open a pull request or submit an issue if you encounter any problems.
