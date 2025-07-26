resource "aws_instance" "dev" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
    
    tags = {
        Name = "test2"
    }
    # lifecycle {
    #     prevent_destroy = true
    #       }
    #       lifecycle {
    #         ignore_changes = [ tag,etc ]
    #       }
    # lifecycle {
    #   create_before_destroy = true
    # }
  
}
 