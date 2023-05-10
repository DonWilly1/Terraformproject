# Configure the AWS Provider
provider "aws" {
  region = var.region
}

 # Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "{var.Prod_vpc}-vpc"
  }
}


#use data source to get all availability zones in region
data "aws_availability_zones" "available_zones"{}



# Create a public subnet 
resource "aws_subnet" "web_public_subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.web_public_subnet-1_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "web_public_subnet-1"
  }
}

# Create a 2nd public subnet 
resource "aws_subnet" "web_public_subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.web_public_subnet-2_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "web_public_subnet-2"
  }
}

# Create a private subnet 
resource "aws_subnet" "priv_app_subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.priv_app_subnet-1_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[1]

  tags = {
    Name = "priv_app_subnet-1"
  }
}

# Create a 2nd private subnet 
resource "aws_subnet" "priv_app_subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.priv_app_subnet-2_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[1]

  tags = {
    Name = "priv_app_subnet-2"
  }
}

# Create a public route table
resource "aws_route_table" "Prod-pub-route-table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Prod-pub-route-table"
  }
}

# Associate public subnets to route table
resource "aws_route_table_association" "Public_sub_association1" {
  subnet_id      = aws_subnet.web_public_subnet-1.id
  route_table_id = aws_route_table.Prod-pub-route-table.id
}

# Associate public subnets to route table
resource "aws_route_table_association" "Public_sub_association2" {
  subnet_id      = aws_subnet.web_public_subnet-2.id
  route_table_id = aws_route_table.Prod-pub-route-table.id
}

# Creating a private route table
resource "aws_route_table" "Prod-priv-route-table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Prod-priv-route-table"
  }
}

# Associate private subnets to route table
resource "aws_route_table_association" "Private_sub_association1" {
  subnet_id      = aws_subnet.priv_app_subnet-1.id
  route_table_id = aws_route_table.Prod-priv-route-table.id
}

# Associate private subnets to route table
resource "aws_route_table_association" "Private_sub_association2" {
  subnet_id      = aws_subnet.priv_app_subnet-2.id
  route_table_id = aws_route_table.Prod-priv-route-table.id
}


# Creating internet Gateway
resource "aws_internet_gateway" "Prod_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Prod_igw"
  }
}

# Associate internet gateway to public subnets
resource "aws_route" "Prod-igw-association" {
  route_table_id         = aws_route_table.Prod-pub-route-table.id
  gateway_id             = aws_internet_gateway.Prod_igw.id
  destination_cidr_block = "0.0.0.0/0"

}

# Create an elastic IP address
resource "aws_eip" "eip1" {
  vpc = true
  depends_on = [aws_internet_gateway.Prod_igw]
}

# Creating NAT gateway
resource "aws_nat_gateway" "Prod-Nat-gateway" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.web_public_subnet-1.id

  tags = {
    Name = "Prod-Nat-gateway"
  }

  depends_on = [aws_internet_gateway.Prod_igw]
}
 
 # Associate NAT gateway to route table
 resource "aws_route" "Prod-Nat-association" {
  route_table_id         = aws_route_table.Prod-priv-route-table.id
  gateway_id             = aws_nat_gateway.Prod-Nat-gateway.id
  destination_cidr_block = "0.0.0.0/0"

 }

# create security group for the ec2 instance
resource "aws_security_group" "Rock_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         =  "tcp"
    cidr_blocks      = ["90.208.14.32/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "Rock_security_group"
  }
}


# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


# launch the ec2 instance and install website
resource "aws_instance" "Rock-server" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web_public_subnet-1.id
  vpc_security_group_ids = [aws_security_group.Rock_security_group.id]
  key_name               = "my-ec2key"

  tags = {
    Name = "ec2-instance-${count.index+1}"
    Environment = "test"
  }
}

# create security group for the database
resource "aws_security_group" "rds_security_group" {
  name        = "rds security group"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "mysql/aurora access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.Rock_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name =  "rds security group"
  }
}


# create the subnet group for the rds instance
resource "aws_db_subnet_group" "rds_subnet_group" {
  name         = "rds-subnets"
  subnet_ids   = [aws_subnet.web_public_subnet-2.id, aws_subnet.priv_app_subnet-2.id]
  description  = "subnets for rds instance"

  tags   = {
    Name = "rds-subnets"
  }
}


# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  engine_version          = "5.7"
  multi_az                = false
  identifier              = "don-rds-instance"
  username                = "william"
  password                = "william15"
  instance_class          = "db.t2.micro"
  allocated_storage       = 200
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  db_name                 = "tenacitydb"
  skip_final_snapshot     = true
}





 