# Variables to be read from config.tfvars
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

variable "bucket" {
  type = string
  description = "Bucket/Dynamodb names"
}

variable "dynamodb_table" {
  type = string
  description = "Bucket/Dynamodb names"
}