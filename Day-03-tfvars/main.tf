resource "aws_instance" "sever1" {
  ami = var.ami_id
  instance_type = var.instance_type
}
resource "aws_instance" "sever2" {
    ami = var.ami_id
    instance_type = var.instance_type
  
}
resource "aws_s3_bucket" "name" {
  bucket = var.aws_s3_bucket
}