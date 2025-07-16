resource "aws_vpc" "cloud_network" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env} Cloud Network"
    env = var.env
    }
  }
  
  resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.cloud_network.id
    cidr_block = var.public_subnet_cidr
    availability_zone = "us-east-2c"
  
    tags = {
      Name = "${var.env} public Subnet"
      env = var.env
    }
  }

  resource "aws_internet_gateway" "public_internet_gateway" {
    vpc_id = aws_vpc.cloud_network.id
  
    tags = {
      Name = "${var.env} Public Internet Gateway"
      env = var.env
    }
    
  }

  resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.cloud_network.id
  
    tags = {
      Name = "${var.env} Public Route Table"
      env = var.env
    }  
  }
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id   
  destination_cidr_block = "0.0.0.0/0"
  gateway_id =  aws_internet_gateway.public_internet_gateway.id
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
  
}

#private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.cloud_network.id
  cidr_block = var.private_subnet_cidr
  availability_zone = "us-east-2b" 
  tags = {
    Name = "${var.env} Private Subnet"
    env = var.env
   }
}

resource "aws_eip" "elastic_ip_for_nat_gateway" {
  count = terraform.workspace == "backend" ? 0 : 1
  vpc = true
  tags = {
    Name = "${var.env} Elastic IP"
    env = var.env
  }
  
}

resource "aws_nat_gateway" "pirvate_gateway" {
  count = terraform.workspace == "backend" ? 0 : 1
  allocation_id = aws_eip.elastic_ip_for_nat_gateway[0].id
  subnet_id = aws_subnet.private_subnet.id
  
  tags = {
    Name = "${var.env} Private Gateway"
    env = var.env
  }

}

resource "aws_route_table" "private_route_table" {
  count = terraform.workspace == "backend" ? 0 : 1
  vpc_id = aws_vpc.cloud_network.id
  
  tags = {
    Name = "${var.env} Private Route Table"
    env = var.env
  } 
}

resource "aws_route" "private_route" {
  count = terraform.workspace == "backend" ? 0 : 1
  route_table_id = aws_route_table.private_route_table[0].id   
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.pirvate_gateway[0].id
}

resource "aws_route_table_association" "private" {
  count = terraform.workspace == "backend" ? 0 : 1
  subnet_id = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table[0].id
  
}