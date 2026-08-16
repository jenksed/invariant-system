terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.44.0"
    }
  }
}

variable "endpoint" {
  type        = string
  description = "Floci endpoint reachable from the IaC tool container."
  default     = "http://floci:4566"
}

variable "namespace" {
  type        = string
  description = "Short lowercase namespace used to isolate tracer resources."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.namespace))
    error_message = "namespace must be 2-31 lowercase letters, digits, or hyphens."
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = var.endpoint
    sqs      = var.endpoint
    dynamodb = var.endpoint
    iam      = var.endpoint
    sts      = var.endpoint
  }
}
