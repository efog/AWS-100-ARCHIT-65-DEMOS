provider "aws" {
  region = "us-west-1"
  alias  = "usw1"
}

terraform {
  backend "s3" {
    bucket = "edgenda-tf-bucket-usw1"
    key    = "edgenda-tf-bucket-usw1.tfstate"
    region = "us-west-1"
  }
}

module "vpc_base_module" {
  source = "./modules/network"
}
