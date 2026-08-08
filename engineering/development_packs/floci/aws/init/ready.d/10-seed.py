#!/usr/bin/env python3
import io
import json
import pathlib
import zipfile

import boto3
from botocore.exceptions import ClientError


INPUT_BUCKET = "arsenal-floci-input"
RESULT_BUCKET = "arsenal-floci-results"
QUEUE_NAME = "arsenal-floci-work"
FUNCTION_NAME = "arsenal-floci-consumer"
ROLE_NAME = "arsenal-floci-lambda"
HANDLER_PATH = pathlib.Path("/opt/arsenal/lambda/handler.py")


def ensure_bucket(s3, name):
    try:
        s3.head_bucket(Bucket=name)
    except ClientError:
        s3.create_bucket(Bucket=name)


def ensure_role(iam):
    trust = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "lambda.amazonaws.com"},
                "Action": "sts:AssumeRole",
            }
        ],
    }
    try:
        return iam.create_role(
            RoleName=ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(trust),
        )["Role"]["Arn"]
    except iam.exceptions.EntityAlreadyExistsException:
        return iam.get_role(RoleName=ROLE_NAME)["Role"]["Arn"]


def lambda_zip():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("handler.py", HANDLER_PATH.read_bytes())
    return buf.getvalue()


def main():
    s3 = boto3.client("s3")
    sqs = boto3.client("sqs")
    iam = boto3.client("iam")
    lamb = boto3.client("lambda")

    ensure_bucket(s3, INPUT_BUCKET)
    ensure_bucket(s3, RESULT_BUCKET)

    queue_url = sqs.create_queue(QueueName=QUEUE_NAME)["QueueUrl"]
    queue_arn = sqs.get_queue_attributes(
        QueueUrl=queue_url,
        AttributeNames=["QueueArn"],
    )["Attributes"]["QueueArn"]

    role_arn = ensure_role(iam)

    try:
        lamb.create_function(
            FunctionName=FUNCTION_NAME,
            Runtime="python3.13",
            Role=role_arn,
            Handler="handler.handler",
            Code={"ZipFile": lambda_zip()},
            Timeout=15,
            Environment={"Variables": {"RESULT_BUCKET": RESULT_BUCKET}},
        )
    except lamb.exceptions.ResourceConflictException:
        pass

    mappings = lamb.list_event_source_mappings(
        FunctionName=FUNCTION_NAME,
        EventSourceArn=queue_arn,
    ).get("EventSourceMappings", [])
    if not mappings:
        lamb.create_event_source_mapping(
            FunctionName=FUNCTION_NAME,
            EventSourceArn=queue_arn,
            BatchSize=1,
            Enabled=True,
        )

    print(
        json.dumps(
            {
                "input_bucket": INPUT_BUCKET,
                "result_bucket": RESULT_BUCKET,
                "queue_url": queue_url,
                "queue_arn": queue_arn,
                "function": FUNCTION_NAME,
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
