terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
}

# Web tier for the new customer portal
resource "aws_security_group" "web01" {
  name        = "web-tier"
  description = "Web tier security group"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for admins"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 

  egress {
    description = "Outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    owner = "platform-team"
  }
}
