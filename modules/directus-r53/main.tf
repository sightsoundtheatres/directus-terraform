# Providers

provider "aws" {
  region = "us-east-1"
}

# Data Sources

data "aws_route53_zone" "main" {
  zone_id = "${var.r53_zone_id}"
}

# Route 53 Records

resource "aws_route53_record" "api4" {
  count = "${length(var.r53_domain_names)}"

  zone_id = "${var.r53_zone_id}"
  name    = "${var.r53_subdomain}"
  type    = "A"

  set_identifier = "${var.prefix}-${lookup(var.r53_domain_names[count.index], "region")}-DirectusAPI"

  health_check_id = "${element(aws_route53_health_check.api.*.id, count.index)}"

  alias {
    name                   = "${lookup(var.r53_domain_names[count.index], "domain_name")}"
    zone_id                = "${var.r53_zone_id}"
    evaluate_target_health = true
  }

  latency_routing_policy {
    region = "${lookup(var.r53_domain_names[count.index], "region")}"
  }
}

resource "aws_route53_record" "api6" {
  count = "${length(var.r53_domain_names)}"

  zone_id = "${var.r53_zone_id}"
  name    = "${var.r53_subdomain}"
  type    = "AAAA"

  set_identifier = "${var.prefix}-${lookup(var.r53_domain_names[count.index], "region")}-DirectusAPI"

  health_check_id = "${element(aws_route53_health_check.api.*.id, count.index)}"

  alias {
    name                   = "${lookup(var.r53_domain_names[count.index], "domain_name")}"
    zone_id                = "${var.r53_zone_id}"
    evaluate_target_health = true
  }

  latency_routing_policy {
    region = "${lookup(var.r53_domain_names[count.index], "region")}"
  }
}

# Route 53 Health Checks

resource "aws_route53_health_check" "api" {
  count = "${length(var.r53_domain_names)}"

  fqdn              = "${lookup(var.r53_domain_names[count.index], "domain_name")}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/server/ping"
  failure_threshold = 1
  request_interval  = 10
  measure_latency   = true

  tags {
    Name        = "${var.prefix}-${lookup(var.r53_domain_names[count.index], "region")}-DirectusAPI-HC"
    Environment = "CMS"
  }
}
