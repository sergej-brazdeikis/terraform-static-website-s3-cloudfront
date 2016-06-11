variable "aws_access_key_id" {}
variable "aws_secret_key" {}
variable "region" { default = "eu-west-1" }

variable "domain" { default = "jevsejev.io" }
variable "domainAlias" { default = "jevsejev_io" }
variable "subdomain" { default = "www.jevsejev.io" }
variable "subdomainAlias" { default = "www_jevsejev_io" }
variable "cdnSubDomain" { default = "cdn.jevsejev.io" }

variable "cf_alias_zone_id" {
  description = "Fixed hardcoded constant zone_id that is used for all CloudFront distributions"
  default = "Z2FDTNDATAQYW2"
}

provider "aws" {
  alias = "prod"

  region = "${var.region}"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_s3_bucket" "website_bucket" {
  provider = "aws.prod"

  bucket = "${var.subdomain}"
  acl = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
      "Principal": "*",
      "Action":"s3:GetObject",
      "Resource":["arn:aws:s3:::${var.subdomain}/*"
      ]
    }
  ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_route53_zone" "route53_zone" {
  provider = "aws.prod"
  name = "${var.domain}"
}

resource "aws_route53_record" "website_route53_record" {
  provider = "aws.prod"
  zone_id = "${aws_route53_zone.route53_zone.zone_id}"
  name = "${var.subdomain}"
  type = "A"

  alias {
    name = "${aws_s3_bucket.website_bucket.website_domain}"
    zone_id = "${aws_s3_bucket.website_bucket.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  provider = "aws.prod"
  depends_on = ["aws_s3_bucket.website_bucket"]
  origin {
    domain_name = "${var.subdomain}.s3.amazonaws.com"
    origin_id = "website_bucket_origin"
    s3_origin_config {
    }
  }
  enabled = true
  default_root_object = "index.html"
  aliases = ["${var.subdomain}"]
  price_class = "PriceClass_200"
  retain_on_delete = true
  default_cache_behavior {
    allowed_methods = [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "website_bucket_origin"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "route53_to_cdn" {
  provider = "aws.prod"
  zone_id = "${aws_route53_zone.route53_zone.zone_id}"
  name = "${var.cdnSubDomain}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id = "${var.cf_alias_zone_id}"
    evaluate_target_health = false
  }
}
