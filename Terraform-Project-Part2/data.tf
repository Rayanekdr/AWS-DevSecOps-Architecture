# Dynamically fetch CloudFront IP ranges
data "aws_ip_ranges" "cloudfront" {
  services = ["CLOUDFRONT"]
  regions  = ["global"]
}
