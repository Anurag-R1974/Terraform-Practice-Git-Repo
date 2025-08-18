resource "aws_instance" "test-ec2" {
  
ami           = var.ami_id
instance_type = var.instance_type
}