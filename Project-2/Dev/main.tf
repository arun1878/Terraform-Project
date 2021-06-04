provider "aws" {
  region = "us-west-2"
  profile="dev"
}

module "my_vpc" {
    source = "../Modules/VPC"
    vpc_cidr = "192.168.0.0/16"
    tenancy = "default"
    vpc_id  = "${module.my_vpc.vpc_id}"
    subnet_cidr ="192.168.1.0/24"
}

module "my_ec2" {
    source = "../Modules/EC2"
    ec2_count = 1
    ami = "ami-03d5c68bab01f3496"
    instance_type = "t3.micro"
    subnet_id = "${module.my_vpc.subnet_id}"
}
