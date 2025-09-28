# Locals = Locals are like variables inside the configuration. works only inside the config
locals {
  region = "us-east-1"
  instance_type = "t2.micro"
}

resource "aws_instance" "example" {
    ami = "ami-0cff7528ff583bf9a"
    instance_type = local.instance_type
    tags = {
        Name = "App-${local-region}"
    }
  
}