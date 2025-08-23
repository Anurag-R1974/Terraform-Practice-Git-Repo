# Create DB Subnet Group
resource "aws_db_subnet_group" "mydb" {
  name       = "mydb-subnet-group"
  subnet_ids = ["subnet-08d5fce807a5773cb", "subnet-0e8c93b78065e092d"]

  tags = {
    Environment = "dev"
    Project     = "terraformrds"
  }
}

# Call terraform-aws-rds module
module "rds" {
  source = "../Day-09-Terraform-Sources/terraform-aws-rds/modules/db_instance"

  identifier          = "mydb-instance"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "mydb"
  username            = "admin"
  password            = "MyStrongPassword123!"
  skip_final_snapshot = true
  publicly_accessible = false

  vpc_security_group_ids = ["sg-01c1f3001ed2fc351"]

  # Use the subnet group we created above
  db_subnet_group_name = aws_db_subnet_group.mydb.name

  tags = {
    Environment = "dev"
    Project     = "terraformrds"
  }
}
