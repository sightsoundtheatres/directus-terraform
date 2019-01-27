variable "aws_region" {
  description = "The AWS region to deploy this module in."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy this module in."
}

variable "lb_sg_id" {
  description = "The ID of the load balancer security group to allow traffic from."
}

variable "lb_tg_id" {
  description = "The ID of the load balancer target group to add tasks to."
}

variable "docker_image" {
  description = "The Docker image to use when deploying Directus."
}

variable "s3_bucket_name" {
  description = "The S3 bucket name for Directus to use."
}

variable "task_count" {
  description = "The desired number of tasks to run in the service."
}

variable "db_endpoint" {
  description = "The Aurora database endpoint to connect to."
}

variable "db_name" {
  description = "The Aurora database name to connect to."
}

variable "db_username" {
  description = "The Aurora database username to connect with."
}

variable "db_password" {
  description = "The Aurora database password to connect with."
}

variable "cdn_domain_name" {
  description = "The domain name of the CDN CloudFront distribution."
}
