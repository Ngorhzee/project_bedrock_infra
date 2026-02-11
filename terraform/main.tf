module "networking" {
  source     = "./networking"
  aws_region = var.aws_region
}

module "eks" {
  source             = "./eks"
  private_subnets_id = module.networking.private_subnets_id
  vpc_id             = module.networking.vpc_id

}
module "storage" {
  source = "./storage"

}

module "database" {
  source = "./database"
  private_subnet_ids = module.networking.private_subnets_id
  eks_security_group_id = module.eks.eks_security_group_id
  vpc_id = module.networking.vpc_id
  oidc_provider = module.eks.oidc_provider

  
}