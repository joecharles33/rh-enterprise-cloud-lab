module "network" {
  source              = "../modules/network"
  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = var.tags
}

module "security" {
  source           = "../modules/security"
  name_prefix      = var.name_prefix
  vpc_id           = module.network.vpc_id
  vpc_cidr         = var.vpc_cidr
  admin_cidr       = var.admin_cidr
  bastion_sg_name  = "${var.name_prefix}-bastion-sg"
  satellite_public = var.satellite_public
  tags             = var.tags
}

module "compute" {
  source                = "../modules/compute"
  name_prefix           = var.name_prefix
  key_name              = var.key_name
  linux_user            = var.linux_user
  bastion_user          = var.bastion_user
  vpc_id                = module.network.vpc_id
  public_subnet_id      = module.network.public_subnet_id
  private_subnet_id     = module.network.private_subnet_id
  sg_bastion_id         = module.security.sg_bastion_id
  sg_target_id          = module.security.sg_target_id
  sg_aap_id             = module.security.sg_aap_id
  rhel_ami_id           = var.rhel_ami_id
  rhel_ami_owners       = var.rhel_ami_owners
  rhel_ami_name_regex   = var.rhel_ami_name_regex
  bastion_instance_type = var.bastion_instance_type
  target_instance_type  = var.target_instance_type
  count_rhel_targets    = var.count_rhel_targets
  enable_aap            = var.enable_aap
  aap_controller_type   = var.aap_controller_type
  aap_hub_type          = var.aap_hub_type
  aap_eda_type          = var.aap_eda_type
  internal_domain       = var.internal_domain
  tags                  = var.tags
}

module "satellite" {
  source                    = "../modules/satellite"
  enable_satellite          = var.enable_satellite
  satellite_public          = var.satellite_public
  name_prefix               = var.name_prefix
  vpc_id                    = module.network.vpc_id
  public_subnet_id          = module.network.public_subnet_id
  private_subnet_id         = module.network.private_subnet_id
  sg_bastion_id             = module.security.sg_bastion_id
  sg_satellite_id           = module.security.sg_satellite_id
  key_name                  = var.key_name
  linux_user                = var.linux_user
  rhel_ami_id               = var.rhel_ami_id
  rhel_ami_owners           = var.rhel_ami_owners
  rhel_ami_name_regex       = var.rhel_ami_name_regex
  satellite_instance_type   = var.satellite_instance_type
  satellite_pulp_size_gb    = var.satellite_pulp_size_gb
  satellite_pulp_iops       = var.satellite_pulp_iops
  satellite_pulp_throughput = var.satellite_pulp_throughput
  internal_domain           = var.internal_domain
  admin_cidr                = var.admin_cidr
  vpc_cidr                  = var.vpc_cidr
  tags                      = var.tags
}
