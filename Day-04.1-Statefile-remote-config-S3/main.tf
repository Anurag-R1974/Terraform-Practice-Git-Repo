resource "aws_vpc" "Dev1" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "Dsub1" {
    cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.Dev1.id
}
resource "aws_subnet" "Dsub2" {
    cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.Dev1.id
}
<<<<<<< HEAD
resource "aws_subnet" "Dsub3" {
    cidr_block = "10.0.3.0/24"
  vpc_id = aws_vpc.Dev1.id
}
=======
resource "aws_subnet" "Dsub4" {
    cidr_block = "10.0.3.0/24"
  vpc_id = aws_vpc.Dev1.id
}
>>>>>>> origin/main
