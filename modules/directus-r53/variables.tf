variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to apply changes to."
}

variable "r53_subdomain" {
  description = "The desired subdomain to create for latency-based routing."
}

variable "r53_domain_names" {
  description = "A list with maps of domains and regions to do latency-based routing and health checks on."
  type        = "list"
}
