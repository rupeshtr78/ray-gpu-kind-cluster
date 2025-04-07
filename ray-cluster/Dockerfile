FROM rayproject/ray:2.41.0

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1


USER root

# Update packages and install any necessary utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    build-essential && \
    rm -rf /var/lib/apt/lists/*


# Install required Python packages for the model and ray serve
# Data Loading & Preprocessing (datasets, pandas, numpy)
# Model Training (transformers, torch, accelerate, DeepSpeed)
# Hyperparameter Tuning (ray[all])
# Serving (starlette, fastapi, uvicorn, vllm)
# Experiment Tracking & Logging (mlflow, tensorboard, wandb, loguru)
# Parameter-Efficient Tuning (peft)
# Reinforcement Learning (ray[rllib] via ray[all], gymnasium)
# Config Management & Productivity (python-dotenv, rich)
RUN pip install --upgrade pip && \
    pip install \
    torch \
    transformers \
    accelerate \
    ray[all] \
    starlette \
    fastapi \
    uvicorn \
    vllm \
    datasets \
    pandas \
    numpy \
    peft \
    deepspeed \
    torchmetrics \
    mlflow \
    tensorboard \
    gymnasium \
    loguru \
    python-dotenv \
    rich

USER ray
WORKDIR /home/ray/app


# Copy script
COPY --chown=ray:users ray-jobs/ /home/ray/app/

# Ray Serve endpoint port
EXPOSE 9023



# Entry point to launch Ray Serve deployment
# CMD ["python", "qwen2-serve.py"]