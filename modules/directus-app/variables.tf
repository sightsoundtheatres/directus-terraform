variable "prefix" {
  description = "The string to prefix all resources with. Some resources have name length limits, so it is recommended to keep this at 5 characters or less."
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to apply changes to. Will create subdomains such as CMS and CMS-API."
}

variable "r53_subdomain" {
  description = "The subdomain to deploy the Directus app at."
}
