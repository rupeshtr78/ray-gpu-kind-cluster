import torch

def check_cuda():
    cuda_available = torch.cuda.is_available()
    print("CUDA Available:", cuda_available)
    if cuda_available:
        print("Current CUDA Device Index:", torch.cuda.current_device())
        print("Current CUDA Device Name:", torch.cuda.get_device_name(0))

import ray

ray.init(address='auto')  # Connect to the existing cluster

@ray.remote(num_gpus=1)
def gpu_test():
    import torch
    return torch.cuda.is_available()

 # Should return True if GPUs are set up correctly

from vllm import AsyncEngineArgs


if __name__ == "__main__":
    check_cuda()
    print(ray.get(gpu_test.remote())) 
    print(AsyncEngineArgs.__dict__)
    print(ray.cluster_resources())  # Shows available CPUs/GPUs



###
# {'accelerator_type:G': 1.0, 'node:__internal_head__': 1.0, 'CPU': 80.0, 'memory': 45750514074.0, 'object_store_memory': 19607363174.0, 'GPU': 2.0, 'node:10.0.0.213': 1.0}
# {'accelerator_type:G': 1.0, 'node:__internal_head__': 0.999, 'CPU': 78.0, 'object_store_memory': 19607363174.0, 'memory': 45750514074.0, 'GPU': 2.0, 'node:10.0.0.213': 1.0}
