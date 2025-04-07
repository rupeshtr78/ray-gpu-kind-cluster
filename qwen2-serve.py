import ray
from ray import serve
from starlette.requests import Request
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch

@serve.deployment(
    num_replicas=1,    # Adjust as needed based on CPU/GPU resources
    ray_actor_options={"num_cpus": 1, "num_gpus": 1}  # Set to 0 for CPU-only, 1 for GPU
)
class Qwen25Server:
    def __init__(self):
        model_name = "Qwen/Qwen2.5-1.5B-Instruct"

        # Load tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)

        # Load model with GPU support
        self.model = AutoModelForCausalLM.from_pretrained(
            model_name,
            device_map="auto",
            torch_dtype=torch.bfloat16,
            trust_remote_code=True
        )

        # Create pipeline for generation
        self.generator = pipeline(
            "text-generation",
            model=self.model,
            tokenizer=self.tokenizer,
            #  device=self.model.device,
            trust_remote_code=True
        )

    def generate(self, prompt: str, max_new_tokens: int = 128) -> str:
        outputs = self.generator(prompt, max_new_tokens=max_new_tokens, do_sample=True)
        generated_text = outputs[0]["generated_text"]
        return generated_text

    # HTTP handling
    async def __call__(self, http_request: Request):
        request_json = await http_request.json()
        prompt = request_json.get("prompt", "")
        max_tokens = request_json.get("max_new_tokens", 128)
        response_text = self.generate(prompt, max_new_tokens=max_tokens)
        return {"response": response_text}

# Initialize and deploy
ray.init()
serve.start(http_options={"host": "0.0.0.0", "port": 9023})
#  Qwen25Server.deploy()
qwen_server=Qwen25Server.bind()
