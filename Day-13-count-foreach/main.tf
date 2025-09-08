variable "ami" {
  type    = string
  default = "ami-00ca32bbc84273381"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "env" {
  type    = list(string)
  default = ["one","two","three"]
}

resource "aws_instance" "sandbox" {
  ami           = var.ami
  instance_type = var.instance_type
  for_each      = toset(var.env) # while using for_each, resources create and deletes in order and with the name in Default
  #count = length(var.env) # if it is count, number begins with '0,1,2,..' and so the names.while deleting order can change and resource namme will renames.

  tags = {
    Name = each.value # for a set, each.value and each.key is the same
  }
}