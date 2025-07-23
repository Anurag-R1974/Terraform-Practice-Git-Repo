terraform {
    backend "s3" {
           bucket = "backendbucket-for-statefile"
           region = "us-east-1"
           key = "terraform.tfstate"
           dynamodb_table = "terraform-state-lock-dynamodb"
           encrypt = true


    }
}