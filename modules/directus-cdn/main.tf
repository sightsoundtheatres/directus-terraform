# Providers

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

# Data Sources

data "aws_route53_zone" "main" {
  provider = "aws.us-east-1"

  zone_id = "${var.r53_zone_id}"
}

# Buckets

resource "aws_s3_bucket" "cdn-us-east-1" {
  provider = "aws.us-east-1"

  bucket = "${var.r53_subdomain}-us-east-1.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  acl    = "private"

  versioning {
    enabled = true
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"

    rules {
      id     = "${lower(var.prefix)}-cdn-us-west-2-replicate"
      status = "Enabled"

      destination {
        bucket = "${aws_s3_bucket.cdn-us-west-2.arn}"
      }
    }
  }

  policy = "${data.aws_iam_policy_document.cdn-us-east-1-bucket-policy.json}"

  tags = {
    Environment = "CMS"
  }
}

resource "aws_s3_bucket" "cdn-us-west-2" {
  provider = "aws.us-west-2"

  bucket = "${var.r53_subdomain}-us-west-2.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  acl    = "private"

  versioning {
    enabled = true
  }

  policy = "${data.aws_iam_policy_document.cdn-us-west-2-bucket-policy.json}"

  tags = {
    Environment = "CMS"
  }
}

# CloudFront

resource "aws_cloudfront_distribution" "cdn" {
  provider = "aws.us-east-1"

  origin {
    domain_name = "${aws_s3_bucket.cdn-us-east-1.bucket_regional_domain_name}"
    origin_id   = "S3-${var.r53_subdomain}-us-east-1.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.cdn-us-west-2.bucket_regional_domain_name}"
    origin_id   = "S3-${var.r53_subdomain}-us-west-2.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.r53_subdomain}-us-east-1.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}" //"OriginGroup-S3-${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}" // Terraform does not support Origin Groups as of AWS provider v1.53.0, so this was changed after initial creation

    forwarded_values {
      query_string = true
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.certificate.id}"
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  tags {
    Environment = "CMS"
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  provider = "aws.us-east-1"
}

# Route 53

resource "aws_route53_record" "cdn4" {
  provider = "aws.us-east-1"

  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn6" {
  provider = "aws.us-east-1"

  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  type    = "AAAA"

  alias {
    name                   = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# ACM

resource "aws_acm_certificate" "certificate" {
  provider = "aws.us-east-1"

  domain_name       = "${var.r53_subdomain}.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}"
  validation_method = "EMAIL"

  tags {
    Environment = "CMS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM

resource "aws_iam_role" "replication" {
  provider = "aws.us-east-1"

  name = "${lower(var.prefix)}-cdn-bucket-replication-role"

  assume_role_policy = "${data.aws_iam_policy_document.replication-assume-role.json}"
}

data "aws_iam_policy_document" "replication-assume-role" {
  provider = "aws.us-east-1"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "replication" {
  provider = "aws.us-east-1"

  name = "${lower(var.prefix)}-cdn-bucket-replication-policy"

  policy = "${data.aws_iam_policy_document.replication-policy.json}"
}

data "aws_iam_policy_document" "replication-policy" {
  provider = "aws.us-east-1"

  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.cdn-us-east-1.arn}",
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]

    resources = [
      "${aws_s3_bucket.cdn-us-east-1.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]

    resources = [
      "${aws_s3_bucket.cdn-us-west-2.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "cdn-us-east-1-bucket-policy" {
  provider = "aws.us-east-1"

  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}",
      ]
    }

    resources = [
      "arn:aws:s3:::${var.r53_subdomain}-us-east-1.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}/*",
    ]
  }
}

data "aws_iam_policy_document" "cdn-us-west-2-bucket-policy" {
  provider = "aws.us-west-2"

  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}",
      ]
    }

    resources = [
      "arn:aws:s3:::${var.r53_subdomain}-us-west-2.${replace(data.aws_route53_zone.main.name, "/[.]$/", "")}/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider = "aws.us-east-1"

  role       = "${aws_iam_role.replication.name}"
  policy_arn = "${aws_iam_policy.replication.arn}"
}
