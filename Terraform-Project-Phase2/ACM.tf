# Remove the ACM Certificate and Validation Resources
# resource "aws_acm_certificate" "rayaneflix_cert" {
#   domain_name       = "RayaneFlix.com"
#   validation_method = "DNS"
# 
#   subject_alternative_names = [
#     "*.RayaneFlix.com"
#   ]
# 
#   tags = {
#     Name = "RayaneFlix Certificate"
#   }
# }

# Remove the DNS Validation Records
# resource "aws_route53_record" "rayaneflix_cert_validation" {
#   for_each = {
#     cert1 = {
#       name  = "_random-token1.RayaneFlix.com"  # Replace with actual token from ACM
#       type  = "CNAME"
#       value = "_another-token1.acm-validation.aws."  # Replace with actual value from ACM
#     }
#   }
# 
#   zone_id = aws_route53_zone.rayane_zone.id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.value]
#   ttl     = 60
# }

# Remove the ACM Certificate Validation
# resource "aws_acm_certificate_validation" "rayaneflix_cert_validation" {
#   certificate_arn         = aws_acm_certificate.rayaneflix_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.rayaneflix_cert_validation : record.fqdn]
# }