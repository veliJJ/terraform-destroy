provider "aws" {
  region = "us-east-1"
}

### EC2 instances

resource "aws_instance" "web_server22" {
  ami                         = "ami-0aaf509a1ebd95e61"
  instance_type               = "t4g.micro"
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.my-subnet01.id
  private_ip                  = "10.0.10.13"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
    tags = {
    Name = "web_server22"
}
}

resource "aws_instance" "web_server01" {
  ami           = "ami-0aaf509a1ebd95e61"
  instance_type = "t4g.micro"

  tags = {
    Name = "web_server01"
}
}

### END OF EC2 instances


### Network settings

resource "aws_vpc" "my-vpc" {
    cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
}
}

resource "aws_internet_gateway" "my-internet-gw" {
  vpc_id = aws_vpc.my-vpc.id

tags = {
  Name = "my-internet-gw"
}
}

resource "aws_subnet" "my-subnet01" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.10.0/24"

  tags = {
    Name = "my-subnet01"
}
}

resource "aws_route_table" "my-routing-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.my-subnet01.id
  route_table_id = aws_route_table.my-routing-table.id
}

### END of Network settings

### Private key for access for web_server22

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/../ansible/terraform-key.pem"
  file_permission = "0600"
}

### END of Private key for access for web_server22

output "ec2_public_ip" {
  value = aws_instance.web_server22.public_ip
}

output "private_key_path" {
  value = "${path.module}/../ansible/terraform-key.pem"
}

### Security group for web_server22

resource "aws_security_group" "web_sg" {
  name        = "allow_web_and_ssh"
  description = "Allow SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_sg"
  }
}

### END Of security group for web_server22


#resource "aws_instance" "web_server03" {
#  ami           = "ami-0aaf509a1ebd95e61"
#  instance_type = "t4g.micro"
#
#  tags = {
#    Name = "web_server10"
#}
#}
