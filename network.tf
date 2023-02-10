##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #

#VPC Creation #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames


}

#internet Gateway creation #
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

 
}
#Elastic IP creation #
resource "aws_eip" "nat-eip" {
  count                     = var.vpc_publicsubnets_count
  vpc                       = true
}

#Private subnet creation#
resource "aws_subnet" "private-subnets" {
  count                   = var.vpc_subnet_count
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  
}
#Create new Public subnet for the ALB & Nat Gateway
resource "aws_subnet" "public-subnets" {
  count                   = var.vpc_publicsubnets_count
  ##cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  cidr_block = count.index == 0 ? local.subnet1 : local.subnet2
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  
}

#Create a NAT Gateway
resource "aws_nat_gateway" "nat" {
  count         = var.vpc_publicsubnets_count
  allocation_id = element(aws_eip.nat-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public-subnets.*.id, count.index)
  depends_on = [aws_internet_gateway.igw]
 
}
#Create a S3 service endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.ca-central-1.s3"
}



# ROUTING #
resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  
}

resource "aws_route_table_association" "rta-subnet-public" {
  count          = var.vpc_subnet_count
  subnet_id      = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.rtb-public.id
}

resource "aws_route_table" "rtb-private" {
  count  = var.vpc_subnet_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }

  
}

resource "aws_route_table_association" "rta-subnet-private" {
  count          = var.vpc_subnet_count
  subnet_id      = element(aws_subnet.private-subnets.*.id,count.index)
  route_table_id = element (aws_route_table.rtb-private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "Brainwork" {
  count          = var.vpc_subnet_count
  route_table_id  = element (aws_route_table.rtb-private.*.id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "Brainwork-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-nginx_alb_sg"
  vpc_id = aws_vpc.vpc.id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags

}

resource "aws_security_group" "asg_sg" {
  name = "${local.name_prefix}-nginx_asg_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

}