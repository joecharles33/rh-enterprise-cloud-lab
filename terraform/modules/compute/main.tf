data "aws_ami" "rhel" {
  count       = var.rhel_ami_id == "" && var.rhel_ami_name_regex != "" && length(var.rhel_ami_owners) > 0 ? 1 : 0
  most_recent = true
  owners      = var.rhel_ami_owners
  filter { name = "name" values = [var.rhel_ami_name_regex] }
  filter { name = "root-device-type" values = ["ebs"] }
}

locals {
  ami_id = var.rhel_ami_id != "" ? var.rhel_ami_id : (length(data.aws_ami.rhel) > 0 ? data.aws_ami.rhel[0].id : "")
}

resource "aws_instance" "bastion" {
  ami                         = local.ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.sg_bastion_id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = merge(var.tags, { Name = "${var.name_prefix}-bastion", Project = "RH-Enterprise-Cloud-Lab" })

  user_data = <<-CLOUD
    #cloud-config
    hostname: bastion.${var.internal_domain}
    fqdn: bastion.${var.internal_domain}
  CLOUD
}

resource "aws_instance" "target" {
  count                  = var.count_rhel_targets
  ami                    = local.ami_id
  instance_type          = var.target_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.sg_target_id]
  key_name               = var.key_name

  tags = merge(var.tags, { Name = "${var.name_prefix}-rhel-${count.index + 1}", Project = "RH-Enterprise-Cloud-Lab" })

  user_data = <<-CLOUD
    #cloud-config
    hostname: rhel-${count.index + 1}.${var.internal_domain}
    fqdn: rhel-${count.index + 1}.${var.internal_domain}
  CLOUD
}

resource "aws_instance" "aap_controller" {
  count                  = var.enable_aap ? 1 : 0
  ami                    = local.ami_id
  instance_type          = var.aap_controller_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.sg_aap_id]
  key_name               = var.key_name
  tags = merge(var.tags, { Name = "${var.name_prefix}-aap-controller", Project = "RH-Enterprise-Cloud-Lab" })
  user_data = <<-CLOUD
    #cloud-config
    hostname: aap-controller.${var.internal_domain}
    fqdn: aap-controller.${var.internal_domain}
  CLOUD
}

resource "aws_instance" "aap_hub" {
  count                  = var.enable_aap ? 1 : 0
  ami                    = local.ami_id
  instance_type          = var.aap_hub_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.sg_aap_id]
  key_name               = var.key_name
  tags = merge(var.tags, { Name = "${var.name_prefix}-aap-hub", Project = "RH-Enterprise-Cloud-Lab" })
  user_data = <<-CLOUD
    #cloud-config
    hostname: aap-hub.${var.internal_domain}
    fqdn: aap-hub.${var.internal_domain}
  CLOUD
}

resource "aws_instance" "aap_eda" {
  count                  = var.enable_aap ? 1 : 0
  ami                    = local.ami_id
  instance_type          = var.aap_eda_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.sg_aap_id]
  key_name               = var.key_name
  tags = merge(var.tags, { Name = "${var.name_prefix}-aap-eda", Project = "RH-Enterprise-Cloud-Lab" })
  user_data = <<-CLOUD
    #cloud-config
    hostname: aap-eda.${var.internal_domain}
    fqdn: aap-eda.${var.internal_domain}
  CLOUD
}
