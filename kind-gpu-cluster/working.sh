#!/bin/bash

helm install gpu-operator \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator --set driver.enabled=false


# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.1/deployments/static/nvidia-device-plugin.yml

kubectl run gpu-test --rm -ti --restart=Never \
--image nvidia/cuda:12.0.1-base-ubuntu22.04 --limits=nvidia.com/gpu=1 -- nvidia-smi


mkdir -p /data/hf-cache
chmod 777 /data/hf-cache

# @TODO add this to cluster
  extraMounts:
  - hostPath: /data/hf-cache
    containerPath: /data/hf-cache

# @TODO add this to cluster
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."10.0.0.213:5050"]
    endpoint = ["http://10.0.0.213:5050"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."10.0.0.213:5050".tls]
    insecure_skip_verify = true  # Only needed for self-signed HTTPS (optional)


# helm upgrade -i nvdp nvdp/nvidia-device-plugin \
#   --version=0.17.1 \
#   --namespace nvidia-device-plugin \
#   --create-namespace \
#   --set config.default=config0 \
#   --set-file config.map.config0=demo/clusters/plugin-cm.yaml \
#   --set-file config.map.config1=demo/clusters/plugin-cm-mixed.yaml

#   helm upgrade -i nvdp nvdp/nvidia-device-plugin \
#   --version=0.17.1 \
#   --namespace nvidia-device-plugin \
#   --create-namespace \
#   --set-file config.map.config=demo/clusters/plugin-cm-mixed.yaml