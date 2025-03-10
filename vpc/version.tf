terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
    # vault = {
    #   source  = "hashicorp/vault"
    #   version = "4.6.0"
    # }
  }
}



provider "aws" {
  region     = "us-east-1"
  # access_key = data.vault_generic_secret.aws_creds.data["aws_access_key_id"]
  # secret_key = data.vault_generic_secret.aws_creds.data["aws_secret_access_key"]
  profile    = "online-testing"
}


# provider "vault" {
#   address = "http://127.0.0.1:8200"
#   token   = var.token
# }