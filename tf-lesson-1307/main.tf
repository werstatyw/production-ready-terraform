terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }

backend "s3" { 
    bucket         = "tf-lesson-1307-backend-backend"
    key            = "terrafrom-state/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-lesson-1307-locks"
    encrypt        = true
  }
  
}

provider "aws" {
    region = "us-east-2"
    profile = "default"
}

locals {
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "vpc" {  
  count = terraform.workspace == "backend" ? 0 : 1
  source = "./modules/vpc"
  env = terraform.workspace
  vpc_cidr = local.vpc_cidr
  public_subnet_cidr = local.public_subnet_cidr
  private_subnet_cidr = local.private_subnet_cidr
  
}
data "aws_ami" "linux_ami" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_security_group" "allow_ssh" {
  count = terraform.workspace == "backend" ? 0 : 1
  name = "allow_ssh_${terraform.workspace}"
  description = "Allows ssh connections and access to the internet"
  vpc_id = module.vpc[0].vpc_id

  ingress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssh ingress"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    self = false

    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]

  egress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "internet egress"
    protocol = "-1"
    from_port = 0
    to_port = 0

    self = false
    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]
}

resource "aws_eip" "testsever13_ip" {
  count = terraform.workspace == "backend" ? 0 : 1
  vpc = true
  instance = aws_instance.testsever13[0].id
  associate_with_private_ip = aws_instance.testsever13[0].private_ip
  tags = {
    Name = "My test instance 13 EIP"
  }
  
}

resource "aws_instance" "testsever13" {
    count = terraform.workspace == "backend" ? 0 : 1
  ami =  "ami-0eb9d6fc9fab44d24"
    instance_type = "t2.nano"
    vpc_security_group_ids = [aws_security_group.allow_ssh[0].id]
    subnet_id = module.vpc[0].public_subnet_id
    key_name = "alexg"
    tags = { 
        Name = "${terraform.workspace} - My test instance 13"
    }
}

module "backend" {
  count = terraform.workspace == "backend" ? 1 : 0
  source = "./modules/backend"
  
}

resource "aws_instance" "private_testsever13" {
    count = terraform.workspace == "backend" ? 0 : 1
  ami =  "ami-0eb9d6fc9fab44d24"
    instance_type = "t2.nano"
    vpc_security_group_ids = [aws_security_group.allow_ssh[0].id]
    subnet_id = module.vpc[0].private_subnet_id
    key_name = "alexg"
    tags = { 
        Name = "${terraform.workspace} - My pirvate test instance 13"
    }
}

module "vpn" {
  count = terraform.workspace == "backend" ? 0 : 1
  source = "./modules/vpn"
  vpc_cidr = local.vpc_cidr
  vpc_id = module.vpc[0].vpc_id
  subnet_ids = [module.vpc[0].public_subnet_id, module.vpc[0].private_subnet_id]
}