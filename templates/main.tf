provider "aws" {
  region  = "us-west-1"
  alias   = "usw1"
  version = "~> 2.7"
}

terraform {
  backend "s3" {
    bucket = "edgenda-tf-bucket-usw1"
    key    = "edgenda-tf-bucket-usw1.tfstate"
    region = "us-west-1"
  }
}

locals {
  tags = {
    owner   = "eb"
    project = "architectures"
  }
}

module "vpc_base_module" {
  source = "./modules/network"
  tags   = "${local.tags}"
}

module "container_cluster_module" {
  source          = "./modules/cluster"
  tags            = "${local.tags}"
  alb_arn         = "${module.vpc_base_module.alb_arn}"
  vpc_id          = "${module.vpc_base_module.vpc_id}"
  subnets         = "${module.vpc_base_module.subnets}"
  security_groups = "${module.vpc_base_module.security_groups}"
}

output "base_vpc_id" {
  value = "${module.vpc_base_module.vpc_id}"
}
