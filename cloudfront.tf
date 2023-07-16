resource "aws_cloudfront_origin_access_identity" "dev" {
}
resource "aws_cloudfront_origin_access_identity" "admin" {
}

resource "aws_s3_bucket" "dev_bucket" {
  bucket = var.dev_bucket
}

resource "aws_s3_bucket" "admin_bucket" {
  bucket = var.admin_bucket
}

data "aws_iam_policy_document" "dev_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.dev_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.dev.iam_arn]
    }
  }
}
data "aws_iam_policy_document" "admin_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.admin_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.admin.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "dev" {
  bucket = aws_s3_bucket.dev_bucket.id
  policy = data.aws_iam_policy_document.dev_s3_policy.json
}
resource "aws_s3_bucket_policy" "admin" {
  bucket = aws_s3_bucket.admin_bucket.id
  policy = data.aws_iam_policy_document.admin_s3_policy.json
}

resource "aws_s3_bucket_acl" "dev_bucket_acl" {
  bucket = aws_s3_bucket.dev_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_acl" "admin_bucket_acl" {
  bucket = aws_s3_bucket.admin_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "dev_bucket" {
  bucket = aws_s3_bucket.dev_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "admin_bucket" {
  bucket = aws_s3_bucket.admin_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_distribution" "dev_com" {
  aliases = [aws_s3_bucket.dev_bucket.bucket]

  custom_error_response {
    error_caching_min_ttl = "10"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = "true"
    default_ttl            = "0"
    max_ttl                = "0"
    min_ttl                = "0"
    smooth_streaming       = "false"
    target_origin_id       = aws_s3_bucket.dev_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
  }

  default_root_object = "index.html"
  enabled             = "true"
  http_version        = "http2"
  is_ipv6_enabled     = "true"

  origin {
    connection_attempts = "3"
    connection_timeout  = "10"
    domain_name         = aws_s3_bucket.dev_bucket.bucket_regional_domain_name
    origin_id           = aws_s3_bucket.dev_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.dev.cloudfront_access_identity_path
    }
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = "false"

  viewer_certificate {
    acm_certificate_arn            = var.dev_cloudfront_certificate_arn
    cloudfront_default_certificate = "false"
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
  tags = {
    Terraform   = "true"
    Name        = var.dev_bucket
  }
}
resource "aws_cloudfront_distribution" "dev_com" {
  aliases = [aws_s3_bucket.admin_bucket.bucket]

  custom_error_response {
    error_caching_min_ttl = "10"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = "true"
    default_ttl            = "0"
    max_ttl                = "0"
    min_ttl                = "0"
    smooth_streaming       = "false"
    target_origin_id       = aws_s3_bucket.admin_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
  }

  default_root_object = "index.html"
  enabled             = "true"
  http_version        = "http2"
  is_ipv6_enabled     = "true"

  origin {
    connection_attempts = "3"
    connection_timeout  = "10"
    domain_name         = aws_s3_bucket.admin_bucket.bucket_regional_domain_name
    origin_id           = aws_s3_bucket.admin_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.admin.cloudfront_access_identity_path
    }
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = "false"

  viewer_certificate {
    acm_certificate_arn            = var.admin_cloudfront_certificate_arn
    cloudfront_default_certificate = "false"
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
  tags = {
    Terraform   = "true"
    Name        = var.admin_bucket
  }
}

