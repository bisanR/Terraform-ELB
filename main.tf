provider "aws" {
    region = "us-east-1"
}
#create two instances
resource "aws_instance" "Instance-One-ELBTom" {
    ami            = "ami-0947d2ba12ee1ff75"
    instance_type  = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "Mykeypair"
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "this is instance 1" > /var/www/html/index.html
                EOF   
    tags = {
        Name = "ELB-Instance-One"
    }
}

resource "aws_instance" "Instance-Two-ELBTom" {
    ami            = "ami-0947d2ba12ee1ff75"
    instance_type  = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "Mykeypair"
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "this is instance 2" > /var/www/html/index.html
                EOF 
    tags = {
        Name = "ELB-Instance-Two"
    }
}

#create security group for ELB
resource "aws_security_group" "SG-Tom" {
  name        = "allow web traffic Tom"
  description = "allow web inbound traffic Tom"

  ingress {
    description = "HTTP Tom"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH Tom"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Tom"
  }
}

#set up default VPC
resource "aws_default_vpc" "default-VPC" {
  tags = {
    Name = "Default VPC"
  }
}

#set up default subnet public 1a
resource "aws_default_subnet" "az1a" {
  availability_zone = "us-east-1a"
  tags = {
    Name = "Default subnet for us-east-1a"
  }
}

#set up default subnet public 1b
resource "aws_default_subnet" "az1b" {
  availability_zone = "us-east-1b"
  tags = {
    Name = "Default subnet for us-east-1b"
  }
}

#create bucket for ELB
resource "aws_s3_bucket" "s3-tom" {
  bucket = "my-bucket-tom"
  acl    = "private"

  tags = {
    Name        = "s3-tom-bucket1"
    Environment = "Dev"
  }
}

#create ELB
resource "aws_lb" "ELB-Tom" {
  name               = "ELB-Tom"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG-Tom.id]
  subnets            = ["aws_subnet.az1a.id","aws_subnet.az1b.id"]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.s3-tom.bucket
    prefix  = "s3-tom"
    enabled = true
  }

  tags = {
    Name = "prod"
  }
}

#target group for ELB
resource "aws_lb_target_group" "TG-Tom" {
  name     = "TG-Tom"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default-VPC.id
}

resource "aws_vpc" "default-VPC" {
  cidr_block = "10.0.0.0/16"
}

