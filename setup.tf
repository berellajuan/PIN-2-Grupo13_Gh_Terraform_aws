provider "aws" {
  region = "us-east-1"
}

# Crear conjunto de opciones DHCP
resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    Name = "terraform-dhcp-options"
  }
}

# Asociar el conjunto de opciones DHCP a la VPC
resource "aws_vpc_dhcp_options_association" "dhcp_options_association" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

# Crear VPC en us-east-1
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "terraform-vpc"
  }
}

# Crear IGW en us-east-1
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Obtener la tabla de rutas principal para modificar
data "aws_route_table" "main_route_table" {
  filter {
    name   = "association.main"
    values = ["true"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
}

# Crear tabla de rutas en us-east-1
resource "aws_default_route_table" "internet_route" {
  default_route_table_id = data.aws_route_table.main_route_table.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Terraform-RouteTable"
  }
}

# Obtener todas las zonas de disponibilidad disponibles en VPC para la región principal
data "aws_availability_zones" "azs" {
  state = "available"
}

# Crear subnet #1 en us-east-1
resource "aws_subnet" "subnet" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
}

# Crear SG para permitir TCP/80 & TCP/22
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic"
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

# Output para la IP pública del servidor web
output "Webserver-Public-IP" {
  value = aws_instance.webserver.public_ip
}