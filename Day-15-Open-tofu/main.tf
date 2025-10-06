provider "aws" {
    region = "us-east-1"
  
}

 resource "aws_instance" "name" {
   ami = "ami-0e449927258d45bc4"
   instance_type = "t2.micro"
   tags = {
    Name = "Dev"
   }

 }
  