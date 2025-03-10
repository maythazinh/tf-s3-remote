# EC2 instance in the subnet
resource "aws_instance" "s3_ec2" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.vpc.outputs.subnet_id
  tags = {
    Name = "test-instance"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "s3remote-by-terraform"
    key     = "vpc/terraform.tfstate"  # Points to the VPC state file
    region  = "us-east-1"
    profile = "tf-state-handler"
  }
}

resource "tls_private_key" "hellocloud_sg_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


output "public_key" {
  value = tls_private_key.hellocloud_sg_keypair.public_key_openssh
}