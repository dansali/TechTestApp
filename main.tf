terraform {
  required_version = ">= 0.12"

  backend "s3" {
    region         = "ap-southeast-2"
    bucket         = "dansali-techtestapp-terraform-state"
    key            = "terraform.tfstate"
    dynamodb_table = "dansali-techtestapp-terraform-state"
    encrypt        = true
  }
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
  name        = "TechTestApp ${var.env}"
  description = "TechTestApp security stuff"

  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "TechTestApp ${var.env}"
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
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "http in"
  }

  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "postgres in private"
  }

  egress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "postgres in private"
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

  egress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "http out for lb from nginx"
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
  depends_on                = [null_resource.local-conf-file]
  ami                       = data.aws_ami.main.id
  instance_type             = "m4.xlarge"

  key_name                  = aws_key_pair.main.key_name
  subnet_id                 = sort(data.aws_subnet_ids.main.ids)[0]
  vpc_security_group_ids    = [aws_security_group.main.id]

  associate_public_ip_address   = true

  tags = {
    Name = "TechTestApp ${var.env}"
  }

  lifecycle {
    create_before_destroy = true
  }

  connection {
    host        = self.public_ip # lol why is this needed
    private_key = file("secret/aws")
    user        = "ec2-user"
  }

  #provisioner "file" {
  #  content     = data.template_file.techtestapp-config.rendered
  #  destination = "app-instance/app/conf.toml"
  #}

  provisioner "local-exec" {
    command = <<EOT
      >ansible.ini;
      echo "[ansible]" | tee -a ansible.ini;
      echo "${aws_instance.main.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=secret/aws" | tee -a ansible.ini;
      echo "[ansible:vars]" | tee -a ansible.ini;
      echo "ansible_python_interpreter=/usr/bin/python3" | tee -a ansible.ini;

      ansible-playbook -u ec2-user --private-key secret/aws -i ansible.ini ansible.yaml;
    EOT
  }
}

output "ec2-instance-public-ip" {
  value = aws_instance.main.public_ip
}

resource "null_resource" "local-conf-file" {
  triggers = {
    template = data.template_file.techtestapp-config.rendered
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.techtestapp-config.rendered}' > app-instance/app/conf.toml"
  }
}

resource "aws_elb" "techtestapp-elb" {
  name = "${var.env}-techtestapp-elb"

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/healthcheck/"
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
    Name = "${var.env}-techtestapp-elb"
  }
}

#resource "aws_autoscaling_attachment" "main" {
#  autoscaling_group_name = aws_autoscaling_group.main.id
#  elb                    = aws_elb.main.id
#}

# Spit out the url for the LB
output "load-balancer-url" {
  value = aws_elb.techtestapp-elb.dns_name
}

resource "aws_db_instance" "main" {
  #final_snapshot_identifier = "${var.env}techtestappdb"
  skip_final_snapshot = true
  vpc_security_group_ids    = [aws_security_group.main.id]
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  instance_class    = "db.t2.medium"
  #deletion_protection = true
  name              = "${var.env}techtestappdb"
  username          = var.dbusername
  password          = var.dbpassword
}

data "template_file" "techtestapp-config" {
  template = file("techtestapp-conf.tmpl")

  vars = {
    databaseusername  = var.dbusername
    databasepassword  = var.dbpassword

    dbname            = "${var.env}techtestappdb"
    dbhost            = aws_db_instance.main.address
    dbport            = aws_db_instance.main.port
  }
}

variable "env" {
  type = string
  description = "Environment!"
}

variable "dbusername" {
  type = string
  description = "Database username"
}

variable "dbpassword" {
  type = string
  description = "Database password"
}

/*variable "instance_count" {
  type = number
  description = "Scale instances"
}*/

variable "dataname" {
  type = string
  description = "Bucket/Dynamodb names"
}