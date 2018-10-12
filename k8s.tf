variable "ssh_key_name" {default = "titan"}
variable "aws_region_name" { default = "us-east-1" }

provider "aws" {
  access_key = "***REMOVED***"
  secret_key = "***REMOVED***"
  region = "${var.aws_region_name}"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.web.id}"
  allocation_id = "${aws_eip.example.id}"
}

resource "aws_instance" "web" {
  ami               = "ami-21f78e11"
  availability_zone = "us-west-2a"
  instance_type     = "t1.micro"
  count =
  tags {
    Name = "HelloWorld"
  }
}

resource "aws_eip" "example" {
  vpc = true
}