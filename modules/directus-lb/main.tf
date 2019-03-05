# Providers

provider "aws" {
  region = "${var.aws_region}"
}

# Data Sources

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "main" {
  zone_id = "${var.r53_zone_id}"
}

# Subnets

resource "aws_subnet" "main" {
  count = 3

  vpc_id                          = "${data.aws_vpc.main.id}"
  availability_zone               = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block                      = "${cidrsubnet(data.aws_vpc.main.cidr_block, 4, 0 + count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(data.aws_vpc.main.ipv6_cidr_block, 8, 0 + count.index)}"
  assign_ipv6_address_on_creation = true

  tags {
    Name        = "${var.prefix}-${var.aws_region}-LB${format("%02d", count.index + 1)}"
    Environment = "CMS"
  }
}

# Security Groups
resource "aws_security_group" "main" {
  name   = "${var.prefix}-${var.aws_region}-LB"
  vpc_id = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags {
    Name        = "${var.prefix}-${var.aws_region}-LB"
    Environment = "CMS"
  }
}

# Application Load Balancers

resource "aws_lb" "main" {
  name               = "${var.prefix}-${var.aws_region}-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.main.id}"]
  subnets            = ["${aws_subnet.main.*.id}"]
  ip_address_type    = "dualstack"

  tags {
    Environment = "CMS"
  }
}

# Listeners

resource "aws_lb_listener" "main" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${aws_acm_certificate.main.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.main.id}"
  }
}

# Target Groups

resource "aws_lb_target_group" "main" {
  name_prefix = "${var.prefix}-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/server/ping"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ACM

resource "aws_acm_certificate" "main" {
  domain_name       = "${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  validation_method = "EMAIL"

  subject_alternative_names = ["${var.r53_subdomain}-${var.aws_region}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"]

  tags {
    Environment = "CMS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route 53

resource "aws_route53_record" "cmsapi4" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.r53_subdomain}-${var.aws_region}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  type    = "A"

  alias {
    name                   = "${aws_lb.main.dns_name}"
    zone_id                = "${aws_lb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cmsapi6" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.r53_subdomain}-${var.aws_region}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  type    = "AAAA"

  alias {
    name                   = "${aws_lb.main.dns_name}"
    zone_id                = "${aws_lb.main.zone_id}"
    evaluate_target_health = false
  }
}
