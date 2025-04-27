resource "aws_instance" "netflix_ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.netflix_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y unzip curl
    sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo unzip awscliv2.zip
    sudo ./aws/install
    sudo apt-get install -y amazon-ssm-agent
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
  EOF

  tags = {
    Name = "netflix-ec2"
  }
}

resource "aws_instance" "modsecurity_waf" {
  ami                         = var.ami
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id # Ensure this is a public subnet
  associate_public_ip_address = true                 # Assign a public IP
  vpc_security_group_ids      = [aws_security_group.waf_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
            #!/bin/bash
            apt-get update
            apt-get install -y apache2 libapache2-mod-security2
            a2enmod security2
            # Install OWASP CRS
            git clone https://github.com/coreruleset/coreruleset.git /etc/modsecurity/crs
            cp /etc/modsecurity/crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf
            echo "Include /etc/modsecurity/crs/*.conf" >> /etc/apache2/mods-enabled/security2.conf
            systemctl restart apache2
  EOF

  tags = {
    Name        = "ModSecurityWAF"
    Environment = "Production"
  }
}