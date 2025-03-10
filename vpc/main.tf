# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "terraform-vpc"
  }
}

# Create a subnet
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
