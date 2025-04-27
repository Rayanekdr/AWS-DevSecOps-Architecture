output "cloudfront_distribution_dns" {
  value = aws_cloudfront_distribution.rayaneflix.domain_name
}


# Output CloudFront IP ranges for debugging purposes (optional)
output "cloudfront_ip_ranges" {
  value = data.aws_ip_ranges.cloudfront.cidr_blocks
}


output "route53_zone_id" {
  value = aws_route53_zone.rayane_zone.zone_id
}

output "route53_zone_name" {
  value = aws_route53_zone.rayane_zone.name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.rayaneflix.domain_name
}

output "route53_alias_record" {
  value = aws_route53_record.rayaneflix_cf_alias.fqdn
}

output "instance_id" {
  value = aws_instance.netflix_ec2.id
}