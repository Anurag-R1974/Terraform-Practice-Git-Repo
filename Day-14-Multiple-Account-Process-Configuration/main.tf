provider "aws" {
    profile = "dev"
    alias = "account1"
}

provider "aws" {
    profile = "test"
    alias = "account2"
}

resource "aws_s3_bucket" "name" {
    bucket = "account1-region"
    provider = aws.account1
  
}

resource "aws_s3_bucket" "name" {
    bucket = "account2-region"
    provider = aws.account2
  
}

# Code Description  = 