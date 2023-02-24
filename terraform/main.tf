terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

variable "ssh_key" {
  type = string
}


data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["earthly-"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["830835002888"]
}

resource "aws_launch_template" "lt" {
  name_prefix   = "earthly"
  image_id      = data.aws_ami.ami.image_id
  instance_type = "t3.micro"
  key_name      = var.ssh_key

}

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["eu-central-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "earthly"
    propagate_at_launch = true
  }
}
