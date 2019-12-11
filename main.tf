terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version                  = "~> 2.41"
  region                   = "ap-southeast-2"
  shared_credentials_file  = "credentials.ini"
}

resource "aws_key_pair" "main" {
  key_name   = "techtestapp-main"
  public_key = file("secret/aws.pub")
}

data "aws_vpc" "main" {
  default     = true
}

data "aws_subnet_ids" "main" {
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group" "main" {
  name        = "TechTestApp"
  description = "TechTestApp security stuff"

  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "TechTestApp"
  }

  lifecycle {
    create_before_destroy = true
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "ssh in"
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "http in LB/public"
  }

  ingress {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "http in"
  }

  egress {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "http out"
  }

  egress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "http out for yum"
  }

  egress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "http out for yum"
  }
}

data "aws_ami" "main" {
  most_recent      = true
  owners           = ["self"]

  filter {
    name           = "tag:TechTestApp"
    values         = ["App"]
  }
}

resource "aws_instance" "main" {
  ami                       = data.aws_ami.main.id
  instance_type             = "t2.medium"

  key_name                  = aws_key_pair.main.key_name
  subnet_id                 = sort(data.aws_subnet_ids.main.ids)[0]
  vpc_security_group_ids    = [aws_security_group.main.id]

  associate_public_ip_address   = true

  tags = {
    Name = "TechTestApp"
  }

  lifecycle {
    create_before_destroy = true
  }

  connection {
    host        = self.public_ip # lol why is this needed
    private_key = file("secret/aws")
    user        = "ec2-user"
  }

  provisioner "local-exec" {
    command = <<EOT
      >ansible.ini;
      echo "[ansible]" | tee -a ansible.ini;
      echo "${aws_instance.main.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=aws" | tee -a ansible.ini;
      ansible-playbook -u ec2-user --private-key secret/aws -i ansible.ini ansible.yaml
    EOT
  }
}

resource "aws_elb" "main-elb" {
  name = "main-elb"

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:3000/"
    interval            = 5
  }

  security_groups             = [aws_security_group.main.id]
  subnets                     = [sort(data.aws_subnet_ids.main.ids)[0]]

  instances                   = [aws_instance.main.id]

  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "main-elb"
  }
}

#resource "aws_autoscaling_attachment" "main" {
#  autoscaling_group_name = aws_autoscaling_group.main.id
#  elb                    = aws_elb.main.id
#}

# Spit out the url for the LB
output "load-balancer-url" {
  value = aws_elb.main-elb.dns_name
}