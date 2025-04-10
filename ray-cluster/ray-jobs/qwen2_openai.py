import ray
from ray import serve
from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch
from fastapi import Body, Request

app = FastAPI()

class CompletionRequest(BaseModel):
    prompt: str
    max_new_tokens: int = 128

@serve.deployment(
    num_replicas=1,  
    ray_actor_options={
        "num_cpus": 12, 
        "num_gpus": 1,
        "memory": 12 * 1024 * 1024 * 1024, 
        "runtime_env": {
            "env_vars": {
                "CUDA_VISIBLE_DEVICES": "1"  # Device ID, e.g., Tesla P40
            }
        }
    }
)
class Qwen25Server:
    def __init__(self):
        model_name = "Qwen/Qwen2.5-1.5B-Instruct"
        self.tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_name, 
            device_map="auto",
            torch_dtype=torch.bfloat16, 
            trust_remote_code=True
        )
        self.generator = pipeline(
            "text-generation",
            model=self.model,
            tokenizer=self.tokenizer,
            trust_remote_code=True
        )

    def generate(self, prompt: str, max_new_tokens: int = 128) -> str:
        outputs = self.generator(prompt, max_new_tokens=max_new_tokens, do_sample=True)
        return outputs[0]["generated_text"]

    async def generate_async(self, prompt: str, max_new_tokens: int = 128) -> str:
        # wrap sync generate function into ray's async call via ray.remote
        result = await ray.remote(self.generate).remote(prompt, max_new_tokens)
        return result

@serve.deployment()
@serve.ingress(app)
class ChatCompletionAPI:
    def __init__(self, model_handle):
        self.model_handle = model_handle

    @app.post("/chat/completions")
    async def chat_completion(self, request: Request):
        payload = await request.json()
        completion_request = CompletionRequest(**payload)

        generated_text = await self.model_handle.generate_async.remote(
            prompt=completion_request.prompt,
            max_new_tokens=completion_request.max_new_tokens
        )
        return {"response": generated_text}

if __name__ == "__main__":
    ray.init(address="auto")
    serve.start(http_options={"host": "0.0.0.0", "port": 8000})

    model = Qwen25Server.bind()
    api = ChatCompletionAPI.bind(model_handle=model)
    
    serve.run(api, route_prefix="/v1")