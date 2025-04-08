import ray
from ray import serve

serve_name = "Qwen25Server"

try:
    ray.init()
    serve.delete(serve_name)
    print("Serve application 'Qwen25Server' deleted successfully.")
except Exception as e:
    print(f"Failed to delete Serve application: {e}")