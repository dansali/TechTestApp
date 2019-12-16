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