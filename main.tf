resource "aws_vpc" "network" {
    cidr_block = "192.168.0.0/16"
    tags = {
      Name = "cdec-b10-vpc"
    }
}   

resource "aws_subnet" "pub" {
    vpc_id = aws_vpc.network.id
    cidr_block = "192.168.0.0/20"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "B10-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.network.id
  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.network.id
    tags = {
      Name = "my-rt"
    }
    route {
        gateway_id = aws_internet_gateway.igw.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "rsa" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.pub.id
}

resource "aws_security_group" "firewall" {
    name        = "new-sg"
    vpc_id      = aws_vpc.network.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }  

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "vm" {
    ami           = "ami-04a0530fbdaac2fd6"
    instance_type = "t3.micro"
    key_name      = "testing3"
    subnet_id = aws_subnet.pub.id
    vpc_security_group_ids = [aws_security_group.firewall.id]
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo systemctl enable apache2
                cat << 'HTML_EOF' | sudo tee /var/www/html/index.html
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Terraform Instance</title>
                </head>
                <body>
                    <h1>Welcome to Terraform</h1>
                    <h1>Deployed by yash-buddhiwant</h1>
                </body>
                </html>
                EOF
    tags = {
        Name = "New Instance"
    }
}