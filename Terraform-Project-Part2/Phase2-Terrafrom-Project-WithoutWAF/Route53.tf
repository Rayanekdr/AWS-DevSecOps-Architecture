# Route53.tf
resource "aws_route53_zone" "rayane_zone" {
  name = "rayaneflix.com"
}

resource "aws_route53_record" "rayaneflix_cf_alias" {
  zone_id = aws_route53_zone.rayane_zone.zone_id
  name    = "www.rayaneflix.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.rayaneflix.domain_name
    zone_id                = aws_cloudfront_distribution.rayaneflix.hosted_zone_id
    evaluate_target_health = false
  }
}