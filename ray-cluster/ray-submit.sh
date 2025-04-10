#!/bin/bash

set -e

ray job submit \
    --address http://localhost:8265 \
    --working-dir ./ray-cluster/ray-jobs \
    --runtime-env-json='{"pip":["torch", "transformers", "ray[serve]", "starlette"]}' \
    -- python qwen2_run.py


echo "Job submitted successfully."