import ray
import logging

# Proper logging configuration
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

ray.init(address='auto')

# Remote task example
@ray.remote
def add(x, y):
    logger.info(f"Running task add with values {x} and {y}")
    return x + y

# Actor to hold and maintain state
@ray.remote
class Counter:
    def __init__(self):
        self.value = 0
        
    def increment(self, amount=1):
        self.value += amount
        logger.info(f"Incremented counter by {amount}, new value: {self.value}")
        return self.value
    
    def get_value(self):
        logger.info(f"Current counter value: {self.value}")
        return self.value

# Actor managing object references explicitly
@ray.remote
class DataStore:
    def __init__(self):
        self.data_refs = []
    
    def add_item(self, item):
        item_ref = ray.put(item)  # Store the object reference in Ray's object store
        # explicitly store ObjectRef, not real object
        logger.info(f"Storing object_ref {item_ref}")
        self.data_refs.append(item_ref)
        return  item_ref
    
    def get_items(self):
        logger.info(f"Retrieving object_refs: {self.data_refs}")
        return self.data_refs

if __name__ == "__main__":
    # Demonstrate remote task
    task_res_ref = add.remote(10, 20)
    print("Task result:", ray.get(task_res_ref)) # Task result: 30
    
    # Counter actor
    counter = Counter.remote()
    results = ray.get([counter.increment.remote(i) for i in [5, 10, 15]])
    print("Counter increments:", results) # Counter increments: [5, 15, 30]
    print("Final counter state:", ray.get(counter.get_value.remote())) # Final counter state: 30
    
    # DataStore actor and object references
    datastore = DataStore.remote()
    # put data into Ray distributed object store
    data_ref = ray.put({"key": "value"})  
    
    # store object reference in DataStore actor
    datastore.add_item.remote(data_ref)  
    retrieved_data_refs = ray.get(datastore.get_items.remote())
    logger.info(f"Retrieved object references: {retrieved_data_refs}") # [ObjectRef(004e05a356423ba532c28ab531948b3c188ac67c0a00000002e1f505)]
    
    # call ray.get() on retrieved object references to get actual values
    retrieved_data = ray.get(retrieved_data_refs)
    print("Stored data inside DataStore:", retrieved_data)
    
    ray.shutdown()