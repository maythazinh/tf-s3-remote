# state.tf
terraform {
  backend "s3" {
    bucket       = "s3remote-by-terraform"
    key          = "ec2/terraform.tfstate"
    region       = "us-east-1"
    profile      = "tf-state-handler"
    use_lockfile = true
    encrypt      = true
      }
}

