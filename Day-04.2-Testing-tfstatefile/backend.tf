terraform {
  backend "s3" {
    bucket = "backendbucket-for-statefile"
    key    = "Day-04.2/terraform.tfstate"
    region = "us-east-1"
  }
}
 