import ray
from ray import serve
from starlette.requests import Request
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch

@serve.deployment(
    num_replicas=1,  
    ray_actor_options={"num_cpus": 12, 
                       "num_gpus": 1,
                       "memory": 12 * 1024 * 1024 * 1024, 
                        "runtime_env": {
                            "env_vars": {
                                "CUDA_VISIBLE_DEVICES": "1"  # Tesla P40
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

    async def __call__(self, http_request: Request):
        request_json = await http_request.json()
        prompt = request_json.get("prompt", "")
        max_tokens = request_json.get("max_new_tokens", 128)
        response_text = self.generate(prompt, max_new_tokens=max_tokens)
        return {"response": response_text}

if __name__ == "__main__":
    # Connect explicitly to the existing Ray Cluster clearly:
    ray.init(address="auto")

    # Explicitly start Ray Serve with proper HTTP host and port clearly:
    serve.start(http_options={"host": "0.0.0.0", "port": 8000})

    # Deploy your Ray Serve deployment clearly and correctly:
    serve.run(Qwen25Server.bind())