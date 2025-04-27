# Security Group for CloudFront
resource "aws_security_group" "cloudfront_sg" {
  name        = "cloudfront_sg"
  description = "Allow traffic from CloudFront"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP/HTTPS traffic"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = slice(tolist(data.aws_ip_ranges.cloudfront.cidr_blocks), 0, 50) # Limit range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP/HTTPS from CloudFront SG
  ingress {
    description     = "Allow HTTP/HTTPS from CloudFront SG"
    from_port       = 80
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cloudfront_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for netflix_ec2
resource "aws_security_group" "netflix_sg" {
  name        = "netflix_sg"
  description = "Allow inbound access for Netflix services"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow HTTPS traffic from CloudFront SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cloudfront_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}