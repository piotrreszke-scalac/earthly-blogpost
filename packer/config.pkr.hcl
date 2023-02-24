packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ssh_key" {
  type        = string
}

source "amazon-ebs" "ubuntu" {
  ami_name         = "earthly"
  force_deregister = true
  instance_type    = "t3.micro"
  region           = "eu-central-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_keypair_name = var.ssh_key
  ssh_private_key_file = "~/.ssh/${var.ssh_key}"
  ssh_username = "ubuntu"
}


build {
  name = "earthly"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "../ansible/playbook.yaml"
    user = "ubuntu"
    use_proxy = false
    inventory_file_template = "earthly ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
  }
}

