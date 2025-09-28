provider "aws" {
  
}

resource "aws_instance" "dev" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
    
    tags = {
        Name = "test2"
    }
}
# "Taint" = Terraform will destroy & recreate resource on the next apply
# Command = terraform taint aws_instance.dev
#           terraform apply

# "Replace" = New way in terraform v0.15+, directly uses in apply
# Command = terraform apply -replace aws_instance.dev

# USE CASES :-
# 1. When Instance Corrupted
# 2. When adding Patches, Software Updates - a new AMI can be used in launch templated to create new sever & delete old servers

# Automatic ASG rollingout new Instances

resource "aws_autoscaling_group" "example" {
    name = "example-asg"
    desired_capacity = 3  # No. of Servers while creating (not permanent)
    max_size = 5          # High Demand max Scale up to 5 servers
    min_size = 2          # Low Demand min Scale down to 2 servers
    vpc_zone_identifier = [aws_subnet.example.id]
    launch_template {
      id = aws_launch_template.example.id
      version = "$Latest"
    }
    instance_refresh {
      strategy = "Rolling"
      preferences {
        min_healthy_percentage = 50  # Min % of Old Servers keep alive while creating new servers 
        instance_warmup = 300        # Wait Time between after Creation of new servers & deletion of set 2 old servers to ensure stability
      }
      triggers = ["launch_template"]
    }
  
}

# WORKSPACE = Creates isolated environments with own state file using the same Terraform code. Ex:- dev,staging and prod.

# terraform workspace list	          =  Show all workspaces
# terraform workspace show	          =  Show current workspace
# terraform workspace new <name>	  =  Create a new workspace
# terraform workspace select <name>	  =  Switch to a workspace
# terraform workspace delete <name>   =  Delete a workspace
# (only works when you are not in that list)	  