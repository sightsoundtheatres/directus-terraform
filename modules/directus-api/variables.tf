variable "aws_region" {
  description = "The AWS region to deploy this module in."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "vpc_cidr" {
  description = "The CIDR to assign to the VPC. Must be a /21."
}

variable "task_count" {
  description = "The number of ECS tasks to start."
}

variable "docker_image" {
  description = "The Docker image to deploy to ECS."
}

variable "db_name" {
  description = "The Aurora database name to create/connect to."
}

variable "db_username" {
  description = "The master username for the Aurora database."
}

variable "db_password" {
  description = "The master password for the Aurora database."
}

variable "db_count" {
  description = "The number of Aurora database instances to put in the cluster."
}

variable "db_replication_source_cluster_arn" {
  description = "The source Aurora database cluster to replicate from in a multi-region architecture. If this is the master cluster, leave empty."
  default     = ""
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to apply changes to."
}

variable "r53_subdomain" {
  description = "The subdomain to give to the Directus API."
}

variable "cdn_bucket_name" {
  description = "The name of the S3 bucket to give Directus access to. Must be in same region as this module is deployed."
}

variable "cdn_domain_name" {
  description = "The domain name of the CDN CloudFront distribution."
}

variable "s3_user_key" {
  description = "The key of the AWS user used to access S3."
}

variable "s3_user_secret" {
  description = "The secret of the AWS user used to access S3."
}
