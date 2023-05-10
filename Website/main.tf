# configure aws provider
provider "aws" {
 region = var.region 
}

# create vpc
module "vpc" {
  source = "../Module/vpc"
  region = var.region           
  project_name = var.project_name
  vpc_cidr = var.vpc_cidr
  web_public_subnet-1_cidr = var.web_public_subnet-1_cidr
  web_public_subnet-2_cidr = var.web_public_subnet-2_cidr
  priv_app_subnet-1_cidr = var.priv_app_subnet-1_cidr
  priv_app_subnet-2_cidr = var.priv_app_subnet-2_cidr
 
}