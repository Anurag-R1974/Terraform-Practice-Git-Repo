terraform {
  backend "s3" {
    bucket = "backendbucket-for-statefile"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
