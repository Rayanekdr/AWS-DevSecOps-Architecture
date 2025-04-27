variable "profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "region" {
  default = "eu-west-3"
  type    = string
}



variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
  default     = "./RayaneSSH.pem"
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-045a8ab02aadf4f88"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "RayaneSSH"
}

