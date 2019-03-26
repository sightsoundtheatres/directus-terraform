# Specify Terraform state backend
terraform {
  backend "s3" {
    // either specify your S3 bucket info here, or provide it at the command line when prompted
  }
}

# Providers

provider "aws" {
  version = "~> 2.3"

  region = "us-east-1"
}

# Data Sources

data "aws_route53_zone" "main" {
  zone_id = "${var.r53_zone_id}"
}

# Local Variables

locals {
  cdn_domain_name = "${var.r53_cdn_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
}

# Directus App

module "app" {
  source = "modules/directus-app"

  prefix        = "${var.prefix}"
  r53_zone_id   = "${var.r53_zone_id}"
  r53_subdomain = "${var.r53_app_subdomain}"
}

# Directus API
# TODO: Pull regions and their specific settings dynamically from Terraform variables. Currently, Terraform does not support "count" with modules, but when that support comes this may be refactored.

module "api-us-east-1" {
  source = "modules/directus-api"

  aws_region      = "us-east-1"
  prefix          = "${var.prefix}"
  vpc_cidr        = "${cidrsubnet(var.cidr, 5, 0)}"
  min_task_count  = 2
  max_task_count  = 5
  docker_image    = "${var.api_docker_image}"
  db_name         = "${var.db_name}"
  db_username     = "${var.db_username}"
  db_password     = "${var.db_password}"
  db_count        = 2
  r53_zone_id     = "${var.r53_zone_id}"
  r53_subdomain   = "${var.r53_api_subdomain}"
  cdn_bucket_name = "${module.directus-cdn.us-east-1_bucket_name}"
  cdn_domain_name = "${local.cdn_domain_name}"
}

module "api-us-west-2" {
  source = "modules/directus-api"

  aws_region      = "us-west-2"
  prefix          = "${var.prefix}"
  vpc_cidr        = "${cidrsubnet(var.cidr, 5, 1)}"
  min_task_count  = 1
  max_task_count  = 3
  docker_image    = "${var.api_docker_image}"
  db_name         = "${var.db_name}"
  db_username     = "${var.db_username}"
  db_password     = "${var.db_password}"
  db_count        = 1
  r53_zone_id     = "${var.r53_zone_id}"
  r53_subdomain   = "${var.r53_api_subdomain}"
  cdn_bucket_name = "${module.directus-cdn.us-west-2_bucket_name}"
  cdn_domain_name = "${local.cdn_domain_name}"

  db_replication_source_cluster_arn = "${module.api-us-east-1.db_cluster_arn}"
}

# CDN for assets
# TODO: Make dynamic like API- add regions dynamically using variables.

module "directus-cdn" {
  source = "modules/directus-cdn"

  prefix        = "${var.prefix}"
  r53_zone_id   = "${var.r53_zone_id}"
  r53_subdomain = "${var.r53_cdn_subdomain}"
  cors_origins  = "${var.cdn_cors_origins}"
}

# Route 53 Latency-Based Routing Records for Directus API

module "api-dns" {
  source = "modules/directus-r53"

  prefix        = "${var.prefix}"
  r53_zone_id   = "${var.r53_zone_id}"
  r53_subdomain = "${var.r53_api_subdomain}"

  r53_domain_names = [
    {
      region      = "us-east-1"
      domain_name = "${var.r53_api_subdomain}-us-east-1.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
    },
    {
      region      = "us-west-2"
      domain_name = "${var.r53_api_subdomain}-us-west-2.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
    },
  ]
}
