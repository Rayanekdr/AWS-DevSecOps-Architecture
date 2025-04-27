resource "null_resource" "provisioners" {
  depends_on = [aws_instance.netflix_ec2]

  # Wait for the instance to be ready
  provisioner "local-exec" {
    command = "sleep 30"
  }

  # Debugging: Print the public IP
  provisioner "local-exec" {
    command = "echo ${aws_instance.netflix_ec2.public_ip}"
  }

  # Save the public IP to the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "echo ${aws_instance.netflix_ec2.public_ip} > /home/ubuntu/public_ip.txt"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Provisioner to install Ansible in a virtual environment
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-venv",
      "python3 -m venv /home/ubuntu/ansible-env",
      "/home/ubuntu/ansible-env/bin/pip install ansible",
      "/home/ubuntu/ansible-env/bin/ansible --version"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Copy the playbook and setup scripts
  provisioner "file" {
    source      = "setup_ec2.yml"
    destination = "/home/ubuntu/setup_ec2.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Copy the Pipeline scripts
  provisioner "file" {
    source      = "RayaneFlix-pipeline.groovy"
    destination = "/home/ubuntu/RayaneFlix-pipeline.groovy"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Copy the password email file
  provisioner "file" {
    source      = "emailP.txt"
    destination = "/home/ubuntu/emailP.txt"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  provisioner "file" {
    source      = "setup_sonarqube.sh"
    destination = "/home/ubuntu/setup_sonarqube.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  provisioner "file" {
    source      = "jenkins_conf.sh"
    destination = "/home/ubuntu/jenkins_conf.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Make the setup scripts executable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_sonarqube.sh",
      "chmod +x /home/ubuntu/jenkins_conf.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }

  # Execute the Ansible playbook
  provisioner "remote-exec" {
    inline = [
      "/home/ubuntu/ansible-env/bin/ansible-playbook /home/ubuntu/setup_ec2.yml -i 'localhost,' -c local"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = aws_instance.netflix_ec2.public_ip
    }
  }
}
