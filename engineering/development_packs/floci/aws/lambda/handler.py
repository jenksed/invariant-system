import hashlib
import json
import os

import boto3


RESULT_BUCKET = os.environ["RESULT_BUCKET"]


def _s3():
    endpoint = os.environ.get("AWS_ENDPOINT_URL")
    if not endpoint:
        raise RuntimeError("AWS_ENDPOINT_URL must be injected for local execution")
    return boto3.client("s3", endpoint_url=endpoint)


def handler(event, context):
    s3 = _s3()
    processed = []

    for record in event.get("Records", []):
        work = json.loads(record["body"])
        bucket = work["bucket"]
        key = work["key"]

        source = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
        result = {
            "bucket": bucket,
            "key": key,
            "bytes": len(source),
            "sha256": hashlib.sha256(source).hexdigest(),
        }
        result_key = f"processed/{key}.json"
        s3.put_object(
            Bucket=RESULT_BUCKET,
            Key=result_key,
            Body=json.dumps(result, sort_keys=True).encode("utf-8"),
            ContentType="application/json",
        )
        processed.append(result_key)

    return {"processed": processed}
