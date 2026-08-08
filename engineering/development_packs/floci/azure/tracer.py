#!/usr/bin/env python3
import hashlib, json, os
from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueServiceClient

conn=os.environ["AZURE_STORAGE_CONNECTION_STRING"]
blob=BlobServiceClient.from_connection_string(conn)
queue=QueueServiceClient.from_connection_string(conn)
source_container="arsenal-floci-input"
result_container="arsenal-floci-results"
queue_name="arsenal-floci-work"
key="golden/input.txt"
payload=b"project-arsenal floci azure golden path\n"
expected_sha=hashlib.sha256(payload).hexdigest()

for name in (source_container,result_container):
    try: blob.create_container(name)
    except ResourceExistsError: pass
try: queue.create_queue(queue_name)
except ResourceExistsError: pass

blob.get_blob_client(source_container,key).upload_blob(payload,overwrite=True)
q=queue.get_queue_client(queue_name)
q.send_message(json.dumps({"container":source_container,"key":key},sort_keys=True))
msg=next(iter(q.receive_messages(messages_per_page=1,visibility_timeout=30)),None)
if msg is None: raise SystemExit("no Azure Queue work item received")
work=json.loads(msg.content)
data=blob.get_blob_client(work["container"],work["key"]).download_blob().readall()
result={"container":work["container"],"key":work["key"],"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
result_key=f"processed/{key}.json"
blob.get_blob_client(result_container,result_key).upload_blob(json.dumps(result,sort_keys=True).encode(),overwrite=True)
q.delete_message(msg.id,msg.pop_receipt)
observed=json.loads(blob.get_blob_client(result_container,result_key).download_blob().readall())
assert observed=={"container":source_container,"key":key,"bytes":len(payload),"sha256":expected_sha}, observed
print(json.dumps(observed,sort_keys=True))
