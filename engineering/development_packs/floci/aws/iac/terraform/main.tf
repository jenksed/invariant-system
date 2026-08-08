locals {
  prefix = "arsenal-iac-${var.namespace}"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.prefix}-artifacts"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "jobs_dlq" {
  name = "${local.prefix}-jobs-dlq"
}

resource "aws_sqs_queue" "jobs" {
  name                       = "${local.prefix}-jobs"
  visibility_timeout_seconds = 45
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.jobs_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_dynamodb_table" "locks" {
  name         = "${local.prefix}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_role" "worker" {
  name = "${local.prefix}-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

output "bucket" {
  value = aws_s3_bucket.artifacts.id
}

output "queue" {
  value = aws_sqs_queue.jobs.name
}

output "dlq" {
  value = aws_sqs_queue.jobs_dlq.name
}

output "table" {
  value = aws_dynamodb_table.locks.name
}

output "role" {
  value = aws_iam_role.worker.name
}
