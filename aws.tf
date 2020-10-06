provider "aws" {  
region     = "eu-north-1"
}

resource "aws_key_pair" "key" {
    key_name="key"
    public_key=file("key.pub")
}
resource "aws_instance" "app" {
    ami="ami-05788af9005ef9a93"
    instance_type="t3.micro"
    user_data=file("userdata.sh")  
    key_name="key"
    vpc_security_group_ids = [aws_security_group.http.id]
}
  
  resource "aws_security_group" "http" {
  name        = "http"
  description = "http inbound traffic"

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.81.134.46/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http"
  }
}
