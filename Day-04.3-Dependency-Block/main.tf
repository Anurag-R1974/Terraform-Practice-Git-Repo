resource "aws_instance" "dev2" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
  
}
resource "aws_vpc" "name" {
    cidr_block = "10.0.0.0/17"
    depends_on = [ aws_instance.dev2 ]
  
}