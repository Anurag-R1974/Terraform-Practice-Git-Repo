# Conditions = How should a resource be created based on some logic

# Example 1 : Creation of S3 Bucket based on Condition
 variable "create_bucket" {
    description = "Set to true to create the S3 Bucket"
    type = bool
    default = true
   
 }
 resource "aws_s3_bucket" "bucket" {
    count = var.create_bucket ? 1 : 0
    bucket = "XXXXXXXX"
    acl    = "private"
    tags = {
        Name = "mybucket"
        Environment = "dev"
    }
 }

 # Example 2 : Condition based regions

 variable "aws_region" {
   description = "The region in which to create the infrastructure"
   type = string
   default = "us-west-2"
   validation {
     condition = var.aws_region == "us-west-2" || var.aws_region == "eu-west-1"
     error_message = "the variable 'aws_region' must be one of the following regions: us-west-2, eu-west-1"

       }
 }
 provider "aws" {
   region = "us-east-1"
 }
 resource "aws_s3_bucket" "dev" {
    bucket = "statefile-configures"
   
 }

# Example 3 : Condition based instance type

variable "ami" {
    type = string
    default = "ami-12345"
}

variable "instance_type" {
    type = string   
    default = "t2.nano" 
}

resource "aws_instance" "dev" {
    ami = var.ami
    instance_type = var.instance_type
    count = var.instance_type == "t2.micro" ? 1 : 0
    tags = {
        Name = "dev-server"
    }

}
# Code Description = In the above example, we are creating an instance only if the instance type is t2.micro. 
# Otherwise, we are not creating the instance