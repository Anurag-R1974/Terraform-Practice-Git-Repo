# VPC
resource "aws_vpc" "DEV" {
  cidr_block = "10.0.0.0/16"
  tags = {   
     Name = "DEV-VPC"
}
  
}
# IG 
resource "aws_internet_gateway" "name" {
  vpc_id = aws_vpc.DEV.id
}
# public RT,edit routes
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.DEV.id 
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.name.id
    }

}
# subnet 
resource "aws_subnet" "public" {
    cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.DEV.id
  availability_zone = "us-east-1a"
}
# route association
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  
}
# SG 
resource "aws_security_group" "allow_tls" {
    name = "allow_tls"
    vpc_id = aws_vpc.DEV.id
    ingress {
        description = "tls to Vpc"
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "tsl to vpc"
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}
# instance 
resource "aws_instance" "public" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public.id
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
  
}
# pvt subnet 
resource "aws_subnet" "private" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.DEV.id
    availability_zone = "us-east-1b"
}
#EIP
resource "aws_eip" "name" {
    domain = "vpc"
  
}

# nat 
resource "aws_nat_gateway" "name" {

    subnet_id = aws_subnet.public.id
    allocation_id = aws_eip.name.id
    

}

#pvt rt and edit routes
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.DEV.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.name.id
    }
  
}
resource "aws_route_table_association" "private" {

subnet_id = aws_subnet.private.id
route_table_id = aws_route_table.private.id
  
}

 
# pvt instance
resource "aws_instance" "private" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private.id
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
}