# Providers

provider "aws" {
  region = "${var.aws_region}"
}

# VPCs

resource "aws_vpc" "main" {
  cidr_block                       = "${var.vpc_cidr}"
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags {
    Name        = "${var.prefix}-${var.aws_region}"
    Environment = "CMS"
  }
}

# Route Tables

resource "aws_default_route_table" "main" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name        = "${var.prefix}-${var.aws_region}-RT"
    Environment = "CMS"
  }
}

# Internet Gateways

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name        = "${var.prefix}-${var.aws_region}-IGW"
    Environment = "CMS"
  }
}

# Network ACLs

resource "aws_default_network_acl" "main" {
  default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"

  ingress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    protocol   = "all"
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }

  egress {
    rule_no    = 100
    protocol   = "all"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }

  ingress {
    rule_no         = 101
    ipv6_cidr_block = "::/0"
    protocol        = "all"
    from_port       = 0
    to_port         = 0
    action          = "allow"
  }

  egress {
    rule_no         = 101
    protocol        = "all"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
    action          = "allow"
  }

  tags {
    Name        = "${var.prefix}-${var.aws_region}-ACL"
    Environment = "CMS"
  }

  lifecycle {
    ignore_changes = ["subnet_ids"]
  }
}
