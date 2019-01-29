variable "cidr" {
  description = "The overall CIDR used between all regions. Must be a /16."
}

variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to add records to."
}

variable "r53_app_subdomain" {
  description = "The subdomain to give to the Directus app."
}

variable "r53_api_subdomain" {
  description = "The subdomain to give to the Directus API."
}

variable "r53_cdn_subdomain" {
  description = "The subdomain to give to the Directus CDN."
}

variable "api_docker_image" {
  description = "The Docker image to deploy to ECS. This will need to be customized for use of S3 or other adapters."
  default     = "directus/api:2.0.15"
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

variable "cdn_cors_origins" {
  description = "The origins to allow CDN resources to be loaded from."
  type = "list"
}
