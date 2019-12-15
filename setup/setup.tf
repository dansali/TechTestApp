provider "aws" {
  version                  = "~> 2.41"
  region                   = "ap-southeast-2"
  shared_credentials_file  = "../secret/credentials.ini"
}

# Let's create our bucket to store our terraform state
# We are encrypting the bucket to hopefully prevent leakage
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket
  acl = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Creating a dynamodb table to lock/unlock the state for safety. Don't be running the same terraform script on 2 pcs at once :(
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

variable "bucket" {
  type = string
  description = "Bucket/Dynamodb names"
}

variable "dynamodb_table" {
  type = string
  description = "Bucket/Dynamodb names"
}

# stop warnings about variables not being used :(
variable "env" {
  type = string
  description = "Environment!"
}

variable "dbusername" {
  type = string
  description = "Database username"
}

variable "dbpassword" {
  type = string
  description = "Database password"
}

variable "instance_count_min" {
  type = number
  description = "Scale instances min"
}

variable "instance_count_max" {
  type = number
  description = "Scale instances max"
}