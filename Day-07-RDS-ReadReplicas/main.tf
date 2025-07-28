
#VPC
resource "aws_vpc" "name" {
cidr_block = "10.0.0.0/16"
enable_dns_support = true
enable_dns_hostnames = true
}

#IG
resource "aws_internet_gateway" "name" {
    vpc_id = aws_vpc.name.id
}

#RT
resource "aws_route_table" "name" {
    vpc_id = aws_vpc.name.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.name.id
    }
  
}

#Subnets
 resource "aws_subnet" "one" {
   cidr_block = "10.0.0.0/24"
   vpc_id = aws_vpc.name.id
   availability_zone = "us-east-1a"
 }

resource "aws_subnet" "two" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.name.id
  availability_zone = "us-east-1b"
}


#Subnet association with RouteTable
resource "aws_route_table_association" "alpha" {
    subnet_id = aws_subnet.one.id
    route_table_id = aws_route_table.name.id
  
}

resource "aws_route_table_association" "beta" {
  subnet_id = aws_subnet.two.id
  route_table_id = aws_route_table.name.id
}

#SecurityGroup/Firewall
resource "aws_security_group" "name" {
    name = "allow tls"
    vpc_id = aws_vpc.name.id

    ingress {
        description = "tls"
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]

    }

    ingress {
        description = "tls"
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "tls"
        from_port = 3306
        to_port = 3306
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


#RDS
resource "aws_db_instance" "default" {
    allocated_storage = 10
    identifier = "book-rds"
    db_name = "mydb"
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    username = "admin"
    password = "admin123"
    db_subnet_group_name = aws_db_subnet_group.sub-grp.id
    parameter_group_name = "default.mysql8.0"
    backup_retention_period = 7               #Retains backups for 7 days
    backup_window = "06:00-07:00"              #Daily backup window "UTC"
       
       # Enable performance insights
       # performance_insights_enabled  =  true   
       # perfomance_insights_retention_period  =  7   # Retain insights for 7 days
    
    maintenance_window = "sun:02:00-sun:05:00"  # Maintenance every Sunday {UTC}
    deletion_protection = false
    skip_final_snapshot = true
    vpc_security_group_ids =  [aws_security_group.name.id]
    depends_on = [ aws_db_subnet_group.sub-grp ]
  
}


#Read-Replica of RDS
resource "aws_db_instance" "read_replica" {
    provider = aws.replica
    replicate_source_db = aws_db_instance.default.arn

    instance_class = "db.t3.micro"
    availability_zone = "us-east-1b"
    publicly_accessible = true
    skip_final_snapshot = true
    depends_on = [ aws_db_instance.default ]
    vpc_security_group_ids =  [aws_security_group.name.id]
    
  
}

#Subnet Group
resource "aws_db_subnet_group" "sub-grp" {
    name = "mycutsubnet"
    subnet_ids = [ aws_subnet.one.id, aws_subnet.two.id ]

    tags = {
      Name = "My DB Subnet Group"
    }
  
}