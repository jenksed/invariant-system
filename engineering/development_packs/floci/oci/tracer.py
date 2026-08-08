#!/usr/bin/env python3
import hashlib, json, os, urllib.error, urllib.parse, urllib.request
base=os.environ["FLOCI_OCI_ENDPOINT"].rstrip("/")
namespace=os.environ.get("FLOCI_OCI_NAMESPACE","floci-local")
tenancy=os.environ.get("FLOCI_OCI_TENANCY","ocid1.tenancy.oc1..flocilocaltenancy0000000000000000000000000000000000000000")
source_bucket="arsenal-floci-input"
result_bucket="arsenal-floci-results"
key="golden/input.txt"
payload=b"project-arsenal floci oci golden path\n"
expected_sha=hashlib.sha256(payload).hexdigest()

def request(method,path,data=None,ctype="application/json"):
    headers={"Content-Type":ctype} if data is not None else {}
    req=urllib.request.Request(base+path,data=data,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=10) as r: return r.status,r.read()
    except urllib.error.HTTPError as e:
        return e.code,e.read()

def create_bucket(name):
    body=json.dumps({"name":name,"compartmentId":tenancy},sort_keys=True).encode()
    status,data=request("POST",f"/n/{namespace}/b",body)
    if status not in (200,409): raise SystemExit(f"create bucket {name} failed: {status} {data!r}")

def obj_path(bucket,name):
    return f"/n/{namespace}/b/{bucket}/o/{urllib.parse.quote(name,safe='/')}"

status,data=request("GET","/n")
if status!=200 or json.loads(data)!=namespace: raise SystemExit(f"unexpected namespace: {status} {data!r}")
create_bucket(source_bucket); create_bucket(result_bucket)
status,data=request("PUT",obj_path(source_bucket,key),payload,"application/octet-stream")
if status!=200: raise SystemExit(f"put source failed: {status} {data!r}")
status,data=request("GET",obj_path(source_bucket,key))
if status!=200 or data!=payload: raise SystemExit("source object round-trip failed")
result={"bucket":source_bucket,"key":key,"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
result_key=f"processed/{key}.json"
encoded=json.dumps(result,sort_keys=True).encode()
status,out=request("PUT",obj_path(result_bucket,result_key),encoded,"application/json")
if status!=200: raise SystemExit(f"put result failed: {status} {out!r}")
status,out=request("GET",obj_path(result_bucket,result_key))
observed=json.loads(out)
assert status==200 and observed=={"bucket":source_bucket,"key":key,"bytes":len(payload),"sha256":expected_sha}, observed
print(json.dumps(observed,sort_keys=True))
