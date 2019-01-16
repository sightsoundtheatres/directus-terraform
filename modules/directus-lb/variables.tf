variable "aws_region" {
  description = "The AWS region to deploy this module in."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy this module in."
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to apply changes to."
}

variable "r53_subdomain" {
  description = "The subdomain to create in Route 53 for the load balancer. (this will be suffixed by the region)"
}
