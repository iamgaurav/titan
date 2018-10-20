variable "key_name" {default = "titan"}
variable "aws_region_name" { default = "us-east-1" }

terraform {
  backend "local" {

  }
}

provider "aws" {
  # Use keys in home dir.
  access_key = ""
  secret_key = ""
  region = "${var.aws_region_name}"
}

data "external" "myipaddr" {
  # Pick one or the other. The second one requires an external script but uses DNS instead of https.
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
  #program = ["bash", "${path.module}/myipaddr.sh"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
# Master Node
resource "aws_instance" "master" {
  count         = "1"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.large"

  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  key_name = "${var.key_name}"

  tags {
    Name   = "master"
  }
}


# Worker Nodes
resource "aws_instance" "workers" {
  count         = "2"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.large"

  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  key_name = "${var.key_name}"

  tags {
    Name   = "worker"
  }
}

resource "aws_security_group" "default" {

}

resource "aws_security_group_rule" "allow_all_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Outbound access to ANY"

  security_group_id = "${aws_security_group.default.id}"
}


resource "aws_security_group_rule" "allow_all_myip" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  cidr_blocks     = ["${data.external.myipaddr.result["ip"]}/32"]
  description     = "Management Ports for K8s Cluster"

  security_group_id = "${aws_security_group.default.id}"
}

resource "aws_security_group_rule" "allow_SG_any" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  self            = true
  description     = "Any from SG for K8s Cluster"

  security_group_id = "${aws_security_group.default.id}"
}

output "master_ip" {
  value = "${aws_instance.master.public_ip}"
}
output "worker_ips" {
  value = ["${aws_instance.workers.*.public_ip}"]
}