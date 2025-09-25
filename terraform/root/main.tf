module "network" {
  source              = "../modules/network"
  vpc_cidr            = "10.60.0.0/16"
  public_subnet_cidr  = "10.60.1.0/24"
  private_subnet_cidr = "10.60.2.0/24"
  az                  = "${var.aws_region}a"

  project = var.project
  env     = var.env
}

module "security" {
  source     = "../modules/security"
  vpc_id     = module.network.vpc_id
  vpc_cidr   = module.network.vpc_cidr
  admin_cidr = var.admin_cidr

  project = var.project
  env     = var.env
}

module "compute" {
  source = "../modules/compute"

  project               = var.project
  env                   = var.env
  aws_region            = var.aws_region
  key_pair_name         = var.key_pair_name
  bastion_instance_type = var.bastion_instance_type

  subnet_public_id  = module.network.subnet_public_id
  subnet_private_id = module.network.subnet_private_id

  sg_admin_id     = module.security.sg_admin_id
  sg_intra_id     = module.security.sg_intra_id
  sg_satellite_id = module.security.sg_satellite_id

  node_groups       = var.node_groups
  satellite_use_eip = true
}
