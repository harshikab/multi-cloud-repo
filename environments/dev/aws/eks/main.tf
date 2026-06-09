
module "iam" {
  source = "./modules/iam"

  cluster-name = var.cluster-name
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_public_subnet = var.vpc_cidr_public_subnet
  vpc_cidr_private_subnet = var.vpc_cidr_private_subnet

  enable_gateway = var.enable_gateway
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr = var.vpc_cidr
  common_tags = var.common_tags
  
  
}

module "vpc_endpoints_private_subnet_1" {
   
  source = "./modules/vpc-endpoints"
  
  region = var.region
  vpc_id = module.vpc.vpc_id
  subnet_ids =  [module.vpc.private_subnet_ids[0]]
  tags = var.common_tags
}

module "vpc_endpoints_private_subnet_2" {
   
  source = "./modules/vpc-endpoints"
  
  region = var.region
  vpc_id = module.vpc.vpc_id
  subnet_ids =  [module.vpc.private_subnet_ids[1]]
  tags = var.common_tags
}

module "vpc_endpoints_private_subnet_3" {
   
  source = "./modules/vpc-endpoints"
  
  region = var.region
  vpc_id = module.vpc.vpc_id
  subnet_ids =  [module.vpc.private_subnet_ids[2]]
  tags = var.common_tags
}
