output "netflix_ec2_public_ip" {
  value = aws_instance.netflix_ec2.public_ip
}
