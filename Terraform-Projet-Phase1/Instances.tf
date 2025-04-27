resource "aws_instance" "netflix_ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.netflix_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "netflix-clone-ec2"
  }

  # Root EBS volume
  root_block_device {
    volume_size = 25          # Set the root volume size to 25 GB
    volume_type = "gp3"       # General Purpose SSD (gp3)
    delete_on_termination = true  # Delete the volume when the instance is terminated
  }
}
