variable "aws_region" {
  description = "The AWS region to deploy this module in."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "vpc_cidr" {
  description = "The CIDR to assign to the VPC. Must be a /21."
}
