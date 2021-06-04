provider "aws" {
  region = "us-west-2"
  profile="dev"
}

resource "aws_instance" "Ubuntu-1" {
  ami           = "ami-03d5c68bab01f3496"
  instance_type = "t3.micro"

  tags = {
    Name = "Ubuntu-dev"
  }
}


/* Create VPC
Create Internet Gateway
Create Custom Route table
Create a subnet
Associate subnet with Route table
Create security group to allow ports 22,80 & 443
Create a network interface with an ip in the subnet that was created in step 4
Assign an elastic IP to the network interface created in step 7
Create Ubuntu and install /enable apache2 */

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "Test"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.test-vpc.id
  
}

resource "aws_route_table" "test-route-table" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "Test-route-table"
  }
}

resource "aws_subnet" "test-subnet" {
    vpc_id = aws_vpc.test-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-2a"
    tags = {
        Name = "Test-subnet"
    }
}

resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.test-subnet.id
  route_table_id = aws_route_table.test-route-table.id
}
resource "aws_security_group" "Allow-web" {
  name        = "Allow-web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    description      = "HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "Allow_Web"
  }
}

resource "aws_network_interface" "Web-NIC" {
  subnet_id       = aws_subnet.test-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.Allow-web.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.Web-NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gateway, aws_instance.Ubuntu]
}

resource "aws_instance" "Ubuntu" {
    ami = "ami-03d5c68bab01f3496"
    instance_type ="t2.micro"
    availability_zone = "us-west-2a"
    key_name = "Terra"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.Web-NIC.id 
    }
    user_data = <<EOF
           #!/bin/bash
           sudo apt update -y
           sudo apt install apache2 -y
           sudo systemctl start apache2
           sudo bash -c 'echo your very first web browser > /var/www/html/index.html'
    EOF

      tags = {
         Name = "Web-server"
      }
}