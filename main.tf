terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key

}

#1.create a vpc

resource "aws_vpc" "production" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "prod"
  }
}

#2.Create a internet gateway

resource "aws_internet_gateway" "myvpc_gw" {

  vpc_id = aws_vpc.production.id
  tags = {
    "Name" = "prod_vpc_gw"
  }
}

#3.create custom Route table

resource "aws_route_table" "myroutetable" {
  vpc_id = aws_vpc.production.id
  tags = {
    key = "prod_routetable"
  }
}

#4.create a subnet

resource "aws_subnet" "prod_sub" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    "Name" = "prod vpc subnet"
  }

}
#5.associate subnet with route table

resource "aws_route_table_association" "My_VPC_association" {

  route_table_id = aws_route_table.myroutetable.id
  subnet_id      = aws_subnet.prod_sub.id


}

#6. create SG to allow port 22,80,443
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.production.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

#7.create a network interface with an ip in that was created in step4

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.prod_sub.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]

  attachment {
    instance     = aws_instance.prod.id
    device_index = 1
  }
}

#8. assign elastic ip to the network interface
resource "aws_eip_association" "eip_assoc" {
  network_interface_id = aws_network_interface.test.id
  allocation_id = aws_eip.webserverip.id
}

resource "aws_eip" "webserverip" {
  vpc = true
}

# 9. add network gateway to routetable

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.myroutetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myvpc_gw.id

}

# 10.Create ec2 instance 

resource "aws_instance" "prod" {
  ami           = "ami-0ed9277fb7eb570c9"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.prod_sub.id
  key_name      = "webserver"



  tags = {
    "Name" = "webserver"
  }

}

output "instance_ip_addr" {
  value = aws_instance.prod.public_ip
}
output "elastic_ip" {
  value = aws_eip.webserverip.address
  
}

#11.Create key pair

resource "tls_private_key" "tlsauth" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.tlsauth.public_key_openssh}"
}

#12. Save private key to local file
resource "local_file" "cloud_pem" { 
  filename = "${path.module}/cloudtls.pem"
  content = tls_private_key.tlsauth.private_key_pem
}

