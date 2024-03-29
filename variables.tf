variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-2"
}

variable "db_password" {
  type = string
}
