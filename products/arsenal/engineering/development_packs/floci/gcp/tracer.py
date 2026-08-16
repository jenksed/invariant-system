#!/usr/bin/env python3
import hashlib, json, os
from google.auth.credentials import AnonymousCredentials
from google.cloud import storage, pubsub_v1
from google.api_core.exceptions import AlreadyExists

project=os.environ.get("FLOCI_GCP_PROJECT","floci-local")
creds=AnonymousCredentials()
storage_client=storage.Client(project=project,credentials=creds)
publisher=pubsub_v1.PublisherClient(credentials=creds)
subscriber=pubsub_v1.SubscriberClient(credentials=creds)
source_bucket="arsenal-floci-input"
result_bucket="arsenal-floci-results"
topic_id="arsenal-floci-work"
sub_id="arsenal-floci-work-sub"
key="golden/input.txt"
payload=b"project-arsenal floci gcp golden path\n"
expected_sha=hashlib.sha256(payload).hexdigest()

for name in (source_bucket,result_bucket):
    try: storage_client.create_bucket(name)
    except AlreadyExists: pass
topic=publisher.topic_path(project,topic_id)
sub=subscriber.subscription_path(project,sub_id)
try: publisher.create_topic(request={"name":topic})
except AlreadyExists: pass
try: subscriber.create_subscription(request={"name":sub,"topic":topic})
except AlreadyExists: pass

storage_client.bucket(source_bucket).blob(key).upload_from_string(payload)
body=json.dumps({"bucket":source_bucket,"key":key},sort_keys=True).encode()
publisher.publish(topic,body).result(timeout=10)
response=subscriber.pull(request={"subscription":sub,"max_messages":1},timeout=10)
if not response.received_messages: raise SystemExit("no Pub/Sub work item received")
msg=response.received_messages[0]
work=json.loads(msg.message.data)
data=storage_client.bucket(work["bucket"]).blob(work["key"]).download_as_bytes()
result={"bucket":work["bucket"],"key":work["key"],"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
result_key=f"processed/{key}.json"
storage_client.bucket(result_bucket).blob(result_key).upload_from_string(json.dumps(result,sort_keys=True),content_type="application/json")
subscriber.acknowledge(request={"subscription":sub,"ack_ids":[msg.ack_id]})
observed=json.loads(storage_client.bucket(result_bucket).blob(result_key).download_as_text())
assert observed=={"bucket":source_bucket,"key":key,"bytes":len(payload),"sha256":expected_sha}, observed
print(json.dumps(observed,sort_keys=True))
