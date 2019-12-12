# TechTestApp

### Summary

This respository consists of multiple tech stacks
* Terraform - Builds AWS instances/resources
* S3/DynamoDB - Holds remote state file/lock
* Ansible - Configures the AWS EC2 instance
* Packer - Builds the AMI for Terraform to deploy to EC2
* Docker Composer - Spawns 2 docker containers on the EC2
* Nginx web server - Proxy for the app
* Go lang container - Builds and runs the app

### Requirements

* Terraform 0.12+
* Ansible 2.9+
* Packer 1.4+
* Git
* Suggested OS: Linux/Mac

### Installation

1) Clone repository:

```
$ git clone https://github.com/dansali/TechTestApp.git
```

2) Modify ```config.tfvars```

3) Add AWS credentials into ```secrets/credentials.ini```

4) Generate new keys

```
$ chmod +x generate_keys.sh
$ ./generate_keys.sh
```

5) Generate new AMI's

```
$ chmod +x packer.sh
$ ./packer.sh
```

6) Execute terraform script

```
$ chmod +x execute_terraform.sh
$ ./execute_terraform.sh
```

7) Wait until LB url is printed, app & rds might take a while to boot

8) To destroy

```
$ chmod +x destroy_terraform.sh
$ ./destroy_terraform.sh
```

### Developed on

* Terraform v0.12.17
* Ansible 2.9.1
* Packer 1.4.5