# cloudfront.tf
resource "aws_cloudfront_distribution" "rayaneflix" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "alb_origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb_origin"

    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
}