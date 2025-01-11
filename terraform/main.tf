provider "aws" {
  region = "us-east-2"  # Set your desired region
}

# Create the SSH key pair (automatically generated)
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
  key_name  = "my-keys4"
}

# Create a Security Group that allows SSH and HTTP access
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create VPC
resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

# Create Subnet
resource "aws_subnet" "test" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TestSubnet"
  }
}

# Create Internet Gateway for VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "TestInternetGateway"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "TestRouteTable"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.test.id
}

# Create EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-039e419d24a37cb82"  # Use the correct AMI for your region
  instance_type = "t2.micro"
  key_name      = tls_private_key.example.public_key_openssh  # Use the generated public key
  security_groups = [aws_security_group.allow_ssh_http.name]
  subnet_id     = aws_subnet.test.id
  associate_public_ip_address = true  # EC2 instance will have a public IP

  tags = {
    Name = "WebServer"
  }

  # Output EC2 Instance IP
  output "instance_ip" {
    value = aws_instance.app_server.public_ip
  }
}

# Run Ansible playbook after instance is created (local-exec)
resource "null_resource" "ansible_playbook" {
  depends_on = [aws_instance.app_server]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.app_server.public_ip}, -u ubuntu --private-key=${tls_private_key.example.private_key_pem} ansible/playbook.yml"
  }
}

output "instance_ip" {
  value = aws_instance.app_server.public_ip
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}