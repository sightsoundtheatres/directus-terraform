variable "aws_region" {
  description = "The AWS region to deploy this module in."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy this database in."
}

variable "web_sg_id" {
  description = "The ID of the web security group to allow traffic from."
}

variable "db_name" {
  description = "The name of the default database to create"
}

variable "db_master_username" {
  description = "The database master username"
}

variable "db_master_password" {
  description = "The database master password"
}

variable "db_replication_source_cluster_arn" {
  description = "If the cluster is a multi-region replica, this is the source cluster ARN"
}

variable "db_instance_count" {
  description = "The number of database instances to provision in the cluster"
}
