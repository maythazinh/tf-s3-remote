# S3 Remote Backend-by-terraform

![image.png](S3%20Remote%20Backend-by-terraform%201af0c05aa8e48066a857e2b089dad6a8/image.png)

# Terraform Note

# Terraform with S3 Backend – Simplified Overview

This guide explains how to set up Terraform for creating an AWS VPC and an EC2 instance. Both configurations store their Terraform state files in a shared S3 bucket. The EC2 configuration uses the VPC’s state (using `terraform_remote_state`) to get the subnet information.

---

## What You’ll Need

- **AWS Credentials:**
    - An IAM user (profile “admin”) with full permissions.
    - A separate IAM user for managing S3 state (profile “tf-state-handler”) with a strict inline policy.
- **Optional:**
    - Vault for securely storing admin secret keys.

---

## Step 1: Configure the VPC

Create a folder (e.g., `vpc/`) with these files:

### 1.1 `vpc/main.tf`

This file defines:
- A VPC with a CIDR block of `10.10.0.0/16`.
- A subnet in that VPC with a CIDR block of `10.10.1.0/24` in `us-east-1a`.
- An output (`subnet_id`) that will be used later by the EC2 configuration.

```hcl
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "terraform-subnet"
  }
}

output "subnet_id" {
  value = aws_subnet.my_subnet.id
}
```

### 1.2 `vpc/state.tf`

This file configures the S3 backend so that the state is stored remotely. It will be saved at:
`s3://terraform-test-state-lab/vpc/terraform.tfstate`.

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-test-state-lab"
    key          = "vpc/terraform.tfstate"
    region       = "us-east-1"
    profile      = "tf-state-handler"
    use_lockfile = true
    encrypt      = true
  }
}
```

### 1.3 `vpc/version.tf`

This file specifies the AWS provider and its version:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "admin"  # This uses your admin credentials
}
```

### 

---

## Step 2: Configure the EC2 Instance

Create another folder (e.g., `ec2/`) with these files:

### 2.1 `ec2/main.tf`

This file does two things:
- **Creates an EC2 Instance**
- **Fetches the VPC State**

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "terraform-test-state-lab"
    key     = "vpc/terraform.tfstate"  # Points to the VPC state file
    region  = "us-east-1"
    profile = "tf-state-handler"
  }
}

resource "aws_instance" "s3_ec2" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.vpc.outputs.subnet_id
  tags = {
    Name = "test-instance"
  }
}
```

### 2.2 `ec2/state.tf`

storing it at:
`s3://terraform-test-state-lab/test-ec2/terraform.tfstate`.

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-test-state-lab"
    key          = "test-ec2/terraform.tfstate"
    region       = "us-east-1"
    profile      = "tf-state-handler"
    use_lockfile = true
    encrypt      = true
  }
}
```

### 2.3 `ec2/version.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "tf-state-handler"  # Use this if not using Vault
  # If using Vault, uncomment and configure the following:
  # access_key = data.vault_generic_secret.aws_creds.data["aws_access_key_id"]
  # secret_key = data.vault_generic_secret.aws_creds.data["aws_secret_access_key"]
}
```

---

## Step 3: Verification

- **S3 Bucket:**
Check that your S3 bucket (`terraform-test-state-lab`) contains both state files:
    - `vpc/terraform.tfstate`
    - `test-ec2/terraform.tfstate`

---

## Using Vault (Optional)

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.6.0"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = var.token
}

data "vault_generic_secret" "aws_creds" {
  path = "secret/testing-user1"  # Update this to your secret path
}
```

*Store your secret keys in Vault manually, via the CLI, or with Terraform as needed.*

---

## Notes on S3 State Files

- **State Versioning:**
Terraform state files stored in S3 can be versioned (viewable via “terraform state version” in the console).