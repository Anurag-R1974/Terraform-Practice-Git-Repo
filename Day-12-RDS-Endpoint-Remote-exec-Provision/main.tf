# ===============================================================================
# TERRAFORM CONFIGURATION
# ===============================================================================
# This configuration creates a complete RDS MySQL system with automated SQL provisioning
# using remote execution. It demonstrates advanced AWS infrastructure patterns including
# VPC networking, security, secrets management, and database automation.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ===============================================================================
# PROVIDER CONFIGURATION
# ===============================================================================
# Provider for read replica (can be in different region)
provider "aws" {
  alias  = "read_replica"
  region = "us-east-1"
}

# ===============================================================================
# NETWORK INFRASTRUCTURE
# ===============================================================================
# Creates isolated network environment with public/private subnets

# Main VPC - Isolated network environment (10.0.0.0/16)
resource "aws_vpc" "name" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for VPC endpoints
  enable_dns_support   = true  # Required for VPC endpoints
  tags = {
    Name = "RDS-VPC"
  }
}

# Internet Gateway - Enables internet access for public subnet
resource "aws_internet_gateway" "name" {
  vpc_id = aws_vpc.name.id
}

# Public Route Table - Routes traffic to internet via IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.name.id
  
  route {
    cidr_block = "0.0.0.0/0"                    # All traffic
    gateway_id = aws_internet_gateway.name.id    # Route to internet
  }
}

# Public Subnet - Hosts EC2 instance with internet access (us-east-1a)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Private Subnet - Hosts RDS database for security (us-east-1b)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "name" {
  # Static IP for NAT Gateway
}

# NAT Gateway - Allows private subnet outbound internet access
resource "aws_nat_gateway" "name" {
  allocation_id = aws_eip.name.id
  subnet_id     = aws_subnet.public.id
}

# Private Route Table - Routes traffic to internet via NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.name.id

  route {
    cidr_block     = "0.0.0.0/0"                # All traffic
    nat_gateway_id = aws_nat_gateway.name.id     # Route via NAT Gateway
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
# ===============================================================================
# SECURITY CONFIGURATION
# ===============================================================================
# Security group controlling network access to EC2 and RDS instances

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Security group for EC2 and RDS access"
  vpc_id      = aws_vpc.name.id

  # Inbound rules - Allow multiple ports for different services
  ingress = [
    for port in ["22", "80", "443", "3306"] : {
      description      = port == "22" ? "SSH access" : port == "3306" ? "MySQL access" : "HTTP/HTTPS access"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]  # Allow from anywhere (restrict in production)
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = false
    }
  ]
  
  # Outbound rules - Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"                    # All protocols
    cidr_blocks      = ["0.0.0.0/0"]          # To anywhere
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# ===============================================================================
# DATABASE INFRASTRUCTURE
# ===============================================================================
# Primary RDS MySQL instance with encryption, backups, and IAM authentication
# Primary RDS MySQL Database
resource "aws_db_instance" "default" {
  # Basic Configuration
  allocated_storage    = 10                    # Storage size in GB
  identifier          = "book-rds"             # RDS instance identifier
  db_name            = "mydb"                 # Initial database name
  engine             = "mysql"                # Database engine
  engine_version     = "8.0"                  # MySQL version
  instance_class     = "db.t3.micro"          # Instance size (free tier)
  
  # Authentication - Retrieved from AWS Secrets Manager
  username = jsondecode(aws_secretsmanager_secret_version.rds_secret.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.rds_secret.secret_string)["password"]
  
  # Network Configuration
  db_subnet_group_name = aws_db_subnet_group.sub-grp.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  publicly_accessible = true                  # Allow external connections
  
  # Database Configuration
  parameter_group_name = "default.mysql8.0"   # MySQL parameter group
  
  # Backup Configuration
  backup_retention_period = 7                 # Retain backups for 7 days
  backup_window          = "06:00-07:00"       # Daily backup window (UTC)
  maintenance_window     = "sun:02:00-sun:05:00" # Weekly maintenance window (UTC)
  
  # Security Configuration
  storage_encrypted = true                     # Encrypt data at rest
  iam_database_authentication_enabled = true  # Enable IAM authentication
  
  # Lifecycle Configuration
  deletion_protection = false                  # Allow deletion (set true for production)
  skip_final_snapshot = true                   # Skip final snapshot on deletion
  
  depends_on = [aws_db_subnet_group.sub-grp]
}

# Read Replica for improved read performance and redundancy
resource "aws_db_instance" "read_replica" {
  provider = aws.read_replica                  # Use replica provider (can be different region)
  
  # Replica Configuration
  replicate_source_db = aws_db_instance.default.arn  # Source database ARN
  instance_class      = "db.t3.micro"                # Same instance class as primary
  availability_zone   = "us-east-1b"                 # Different AZ for redundancy
  
  # Network Configuration
  publicly_accessible = false                        # Keep replica private
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  # Security Configuration
  storage_encrypted   = true                         # Inherit encryption from primary
  skip_final_snapshot = true
  
  depends_on = [aws_db_instance.default]
}

# DB Subnet Group - Spans multiple AZs for high availability
resource "aws_db_subnet_group" "sub-grp" {
  name       = "mycutsubnet"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]  # Multi-AZ deployment

  tags = {
    Name = "My DB Subnet Group"
  }
}
# ===============================================================================
# SECRETS MANAGEMENT
# ===============================================================================
# AWS Secrets Manager for secure credential storage and rotation

# Secret container for RDS credentials
resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "rds-credentials"
  description = "RDS database credentials for secure access"
}

# Secret version containing actual username/password
resource "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = "admin"         # Database admin username
    password = "Password123!"  # Database password (use strong password in production)
  })
}

# VPC Endpoint for private access to Secrets Manager
resource "aws_vpc_endpoint" "secretmanager" {
  vpc_id              = aws_vpc.name.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"                              # Interface endpoint for private access
  subnet_ids          = [aws_subnet.private.id]                 # Deploy in private subnet
  security_group_ids  = [aws_security_group.allow_ssh.id]
  private_dns_enabled = true                                     # Enable private DNS resolution
}

# ===============================================================================
# COMPUTE INFRASTRUCTURE
# ===============================================================================
# EC2 instance for database operations and SQL script execution

# Ubuntu Server instance for running MySQL client and executing SQL scripts
resource "aws_instance" "sql_runner" {
  # Instance Configuration
  ami           = "ami-0360c520857e3138f"  # Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"               # Free tier eligible
  key_name      = "USKEY1"                 # SSH key pair for access
  
  # Network Configuration
  subnet_id                   = aws_subnet.public.id              # Deploy in public subnet
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id] # Attach security group
  associate_public_ip_address = true                               # Assign public IP
  
  # User Data Script - Runs on instance startup
  user_data = <<-EOF
    #!/bin/bash
    apt update -y                    # Update package lists
    apt install -y mysql-client      # Install MySQL client for database connections
  EOF
  
  # Storage Configuration
  root_block_device {
    encrypted = true  # Encrypt EBS volume for security
  }
  
  # Monitoring Configuration
  monitoring = true   # Enable detailed CloudWatch monitoring
  
  tags = {
    Name = "SQL Runner"
  }
}

# ===============================================================================
# AUTOMATED SQL PROVISIONING
# ===============================================================================
# Remote execution of SQL scripts using null_resource and provisioners

resource "null_resource" "remote_sql_exec" {
  # Ensure RDS and EC2 are ready before executing
  depends_on = [aws_db_instance.default, aws_instance.sql_runner]

  # SSH Connection Configuration
  connection {
    type        = "ssh"
    user        = "ubuntu"                                           # Ubuntu default user
    private_key = file("C:/Users/SAI ANURAG/Downloads/USKEY1.pem")  # SSH private key
    host        = aws_instance.sql_runner.public_ip                 # Connect to EC2 public IP
    timeout     = "5m"                                              # Connection timeout
  }

  # File Provisioner - Upload SQL script to EC2 instance
  provisioner "file" {
    source      = "init.sql"      # Local SQL file
    destination = "/tmp/init.sql" # Remote destination on EC2
  }

  # Remote Execution Provisioner - Execute commands on EC2 instance
  provisioner "remote-exec" {
    inline = [
      # System Updates and MySQL Client Installation
      "sudo apt update -y",                    # Update package lists
      "sudo apt install -y mysql-client",      # Install MySQL client
      
      # Execute SQL Script on RDS Database
      "mysql -h ${aws_db_instance.default.address} -u admin -pPassword123! mydb < /tmp/init.sql",
      
      # Verification Commands - Check if SQL execution was successful
      "echo 'Verifying database setup...'",
      "mysql -h ${aws_db_instance.default.address} -u admin -pPassword123! mydb -e 'SHOW TABLES;'",
      "mysql -h ${aws_db_instance.default.address} -u admin -pPassword123! mydb -e 'SELECT COUNT(*) FROM users; SELECT COUNT(*) FROM products; SELECT COUNT(*) FROM orders;'"
    ]
  }

  # Trigger Configuration - Force re-execution on every apply
  triggers = {
    always_run = timestamp()  # Always run provisioner (useful for testing)
  }
}


